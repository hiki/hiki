# -*- coding: utf-8 -*-
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require "nkf"
require "cgi/util"
require "erb"

require "docdiff/difference"
require "docdiff/document"
require "docdiff/view"
require "docdiff/diff/unidiff"

class String
  # all instance methods added in String class will be obsoleted in the
  # future release.

  def to_euc
    NKF.nkf("-m0 -e", self)
  end

  def to_sjis
    NKF.nkf("-m0 -s", self)
  end

  def to_jis
    NKF.nkf("-m0 -j", self)
  end

  def to_utf8
    NKF.nkf("-m0 -w", self)
  end

  unless method_defined?(:b)
    def b
      dup.force_encoding(Encoding::ASCII_8BIT)
    end
  end
end

class Hash
  alias :key :index unless method_defined?(:key)
end

module Hiki
  class PluginException < Exception; end

  module Util
    include ERB::Util

    # URL-encode a string.
    #   url_encoded_string = escape("'Stop!' said Fred")
    #      # => "%27Stop%21%27+said+Fred"
    def escape(string)
      # .b needs to avoid ruby 1.9.3's CGI.escape encoding bug, fixed in 2.0.0
      CGI.escape(string.b)
    end

    # URL-decode a string.
    #   string = unescape("%27Stop%21%27+said+Fred")
    #      # => "'Stop!' said Fred"
    def unescape(string)
      CGI.unescape(string)
    end

    # Escape special characters in HTML, namely &\"<>
    #   escapeHTML('Usage: foo "bar" <baz>')
    #      # => "Usage: foo &quot;bar&quot; &lt;baz&gt;"
    def escapeHTML(string)
      CGI.escapeHTML(string)
    end

    # Unescape a string that has been HTML-escaped
    #   unescapeHTML("Usage: foo &quot;bar&quot; &lt;baz&gt;")
    #      # => "Usage: foo \"bar\" <baz>"
    def unescapeHTML(string)
      CGI.unescapeHTML(string)
    end

    alias escape_html escapeHTML
    alias h escapeHTML
    alias unescape_html unescapeHTML

    def set_conf(conf)
      @conf = conf
    end

    module_function :escape, :unescape, :escape_html, :h, :unescape_html, :set_conf

    def plugin_error(method, e)
      msg = "<strong>#{e.class} (#{h(e.message)}): #{h(method)}</strong><br>"
      msg << "<strong>#{e.backtrace.join("<br>\n")}</strong>" if @conf.plugin_debug
      msg
    end

    def cmdstr(cmd, param)
      "?c=#{cmd};#{param}"
    end

    def title(s)
      h("#{@conf.site_name} - #{s}")
    end

    def view_title(s)
      %Q!<a href="#{@conf.cgi_name}#{cmdstr('search', "key=#{escape(s)}") }">#{h(s)}</a>!
    end

    def format_date(tm)
      tm.strftime(@conf.msg_time_format).sub(/#DAY#/, "(#{@conf.msg_day[tm.wday]})")
    end

    def get_common_data(db, plugin, conf)
      data = {}
      data[:author_name] = conf.author_name
      data[:view_style]  = conf.use_sidebar ? h(conf.main_class) : "hiki" # for tDiary theme
      data[:cgi_name]    = conf.cgi_name
      if conf.use_sidebar
        t = db.load_cache(conf.side_menu)
        unless t
          m = db.load(conf.side_menu) || ""
          parser = conf.parser.new(conf)
          t = parser.parse(m)
          db.save_cache(conf.side_menu, t)
        end
        f = conf.formatter.new(t, db, plugin, conf, "s")
        data[:sidebar]   = f.to_s
        data[:main_class]    = conf.main_class
        data[:sidebar_class] = h(conf.sidebar_class)
      else
        data[:sidebar] = nil
      end
      data
    end

    def word_diff(src, dst, digest = false)
      src_doc = Document.new(src, @charset, CharString.guess_eol($/))
      dst_doc = Document.new(dst, @charset, CharString.guess_eol($/))
      diff = compare_by_line_word(src_doc, dst_doc)
      overriding_tags = {
        start_common: "",
        end_common: "",
        start_del: '<del class="deleted">',
        end_del: "</del>",
        start_add: '<ins class="added">',
        end_add: "</ins>",
        start_before_change: '<del class="deleted">',
        end_before_change: "</del>",
        start_after_change: '<ins class="added">',
        end_after_change: "</ins>",
      }
      if digest
        return View.new(diff, src.encoding, src.eol).to_html_digest(overriding_tags, false).join.gsub(%r|<br />|, "").gsub(%r|\n</ins>|, "</ins>\n") # "
      else
        return View.new(diff, src.encoding, src.eol).to_html(overriding_tags, false).join.gsub(%r|<br />|, "").gsub(%r|\n</ins>|, "</ins>\n") # "
      end
    end

    def word_diff_text(src, dst, digest = false)
      src_doc = Document.new(src, @charset)
      dst_doc = Document.new(dst, @charset)
      diff = compare_by_line_word(src_doc, dst_doc)
      if digest
        return View.new(diff, src.encoding, src.eol).to_wdiff_digest({}, false).join.gsub(%r|\n\+\}|, "+}\n")
      else
        return View.new(diff, src.encoding, src.eol).to_wdiff({}, false).join.gsub(%r|\n\+\}|, "+}\n")
      end
    end

    def unified_diff(src, dst, context_lines = 3)
      return h(Diff.new(src.split(/^/), dst.split(/^/)).ses.unidiff("", context_lines))
    end

    def redirect(request, url, cookies = nil)
      url.sub!(%r|/\./|, "/")
      header = {}
      header["cookie"] = cookies if cookies
      header["type"] = "text/html"
      body = %Q[
               <html>
               <head>
               <meta http-equiv="refresh" content="0;url=#{url}">
               <title>moving...</title>
               </head>
               <body>Wait or <a href="#{url}">Click here!</a></body>
               </html>]
      response = Hiki::Response.new(body, 200, header)
      if Object.const_defined?(:Rack)
        cookies = response.header.delete("cookie")
        if cookies
          cookies.each do |cookie|
            response.set_cookie(cookie.name, cookie.value)
          end
        end
      end
      response
    end

    def sendmail(subject, body)
      require "net/smtp"
      require "time"
      if @conf.mail && !@conf.mail.empty? && @conf.smtp_server
        Net::SMTP.start(@conf.smtp_server, 25) do |smtp|
          from_addr = @conf.mail_from ? @conf.mail_from : @conf.mail[0]
          from_addr.untaint
          to_addrs = @conf.mail
          to_addrs.each{|a| a.untaint}

          smtp.send_mail <<EndOfMail, from_addr, *to_addrs
From: #{from_addr}
To: #{to_addrs.join(",")}
Subject: #{NKF.nkf('-Mw', subject)}
Date: #{Time.now.rfc2822}
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: Base64
X-Mailer: Hiki #{Hiki::VERSION}

#{NKF.nkf('-MBw', body)}
EndOfMail
        end
      end
    end

    def send_updating_mail(page, type, text="")
      body = <<EOS
#{'-' * 25}
EOS
      info = {}
      key_max_len = 0
      [
        "HTTP_CLIENT_IP",
        "HTTP_X_FORWARDED_FOR",
        "HTTP_X_REAL_IP",
        "REMOTE_ADDR",
        "REMOTE_HOST",
        "REMOTE_USER",
        "HTTP_USER_AGENT",
      ].each do |key|
        if ENV[key]
          info[key] = ENV[key]
          if key_max_len < key.size
            key_max_len = key.size
          end
        end
      end
      info["URL"] = if Object.const_defined?(:Rack) && @request
                      index_url = (@request.base_url + @conf.cgi_name).sub(%r|/\./|, "/")
                      "#{index_url}?#{escape(page)}"
                    else
                      "#{@conf.index_url}?#{escape(page)}"
                    end
      info.each do |key, value|
        body << sprintf("%*s = %s\n", key_max_len, key, value)
      end
      body << <<EOS
#{'-' * 25}
#{text}
EOS
      sendmail("[#{@conf.site_name}] #{type} - #{page}", body)
    end

    def theme_url
      if /\.css\Z/i =~ @conf.theme_url
        @conf.theme_url
      else
       "#{@conf.theme_url}/#{@conf.theme}/#{@conf.theme}.css"
      end
    end

    def base_css_url
      if /\.css\Z/i =~ @conf.theme_url
        "#{File.dirname(@conf.theme_url)}/../hiki_base.css"
      else
       "#{@conf.theme_url}/hiki_base.css"
      end
    end

    def shorten(str, len = 200)
      arr = str.split(//)
      if arr.length <= len - 2
        str
      else
        arr[0...len-2].join("") + ".."
      end
    end

    # TODO remove this method in future release
    def to_native(str, charset=nil)
      str.encode(@charset, charset)
    end

    def compare_by_line(doc1, doc2)
      Difference.new(doc1.split_to_line, doc2.split_to_line)
    end

    def compare_by_line_word(doc1, doc2)
      lines = compare_by_line(doc1, doc2)
      words = Difference.new
      lines.each{|line|
        if line.first == :change_elt
          before_change = Document.new((line[1] || []).join,
                                       doc1.encoding, doc1.eol)
          after_change  = Document.new((line[2] || []).join,
                                       doc2.encoding, doc2.eol)
          Difference.new(before_change.split_to_word,
                         after_change.split_to_word).each{|word|
            words << word
          }
        else  # :common_elt_elt, :del_elt, or :add_elt
          words << line
        end
      }
      words
    end
  end
end
