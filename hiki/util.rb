# $Id: util.rb,v 1.25 2005-01-14 01:39:46 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'nkf'
require 'cgi'
require 'net/smtp'
require 'time'
require 'amrita/template'
require 'algorithm/diff'
require 'docdiff/difference'
require 'docdiff/document'
require 'docdiff/view'

class String
  def to_euc
    NKF::nkf('-m0 -e', self)
  end

  def to_sjis
    NKF::nkf('-m0 -s', self)
  end

  def to_jis
    NKF::nkf('-m0 -j', self)
  end
  
  def escape
    CGI::escape(self)
  end

  def unescape
    CGI::unescape(self)
  end

  def escapeHTML
    CGI::escapeHTML(self)
  end

  def unescapeHTML
    CGI::unescapeHTML(self)
  end

  def sanitize
    SanitizedString::new(self)
  end
end

class Hash
  alias :key :index unless method_defined?(:key)
end

module Hiki
  class PluginException < Exception; end

  module Util
    def csv_split( source, delimiter = ',' )
      status = :IN_FIELD
      csv = []
      csv.push(last = "")
      while !source.empty?
        case status
        when :IN_FIELD
          case source
          when /^'/
            source = $'
            last.concat "'"
            status = :IN_QFIELD
          when /^#{delimiter}/
            source = $'
            csv.push(last = "")
          when /^(\\|\s)/
            source = $'
          when /^([^#{delimiter}'\\\s]*)/
            source = $'
            last.concat $1
          end
        when :IN_QFIELD
          case source
          when /^'/
            source = $'
            last.concat "'"
            status = :IN_FIELD
          when /^(\\)/
            source = $'
            last.concat $1
            status = :IN_ESCAPE
          when /^([^'\\]*)/
            source = $'
            last.concat $1
          end
        when :IN_ESCAPE
          if /^(.)/ =~ source
            source = $'
            last.concat $1
          end
          status = :IN_QFIELD
        end
      end
      csv
    end

    def plugin_error( method, e )
      msg = "<strong>#{e.class}(#{e.message}): #{method.escapeHTML}</strong><br>"
      msg << "<strong>#{e.backtrace.join("<br>\n")}</strong>" if @conf.plugin_debug
      msg
    end

    def cmdstr( cmd, param )
      "?c=#{cmd};#{param}"
    end

    def title( s )
      "#{@conf.site_name} - #{s}"
    end

    def view_title( s )
      %Q!<a href="#{@conf.cgi_name}#{cmdstr('search', "key=#{s.escape}") }">#{s.escapeHTML}</a>!
    end

    def format_date( tm )
      tm.strftime(@conf.msg_time_format).sub(/#DAY#/, "(#{@conf.msg_day[tm.wday]})")
    end

    def get_common_data( db, plugin, conf )
      data = Hash::new
      data[:author_name] = conf.author_name
      data[:view_style]  = conf.use_sidebar ? conf.main_class : 'hiki' # for tDiary theme
      data[:cgi_name]    = conf.cgi_name
      if conf.use_sidebar
        parser = conf.parser.new( conf )
        m = db.load( conf.side_menu ) || ''
        t = parser.parse( m )
        f = conf.formatter.new( t, db, plugin, conf, 's' )
        data[:sidebar]   =  {:menu => f.to_s.sanitize}
        data[:main_class]    = conf.main_class
        data[:sidebar_class] = conf.sidebar_class
      else
        data[:sidebar] = nil
      end
      data
    end

    def diff_t( s1 , s2 )
      s1 = s1 || ''
      s2 = s2 || ''
      a1 = s1.split( "\n" ).collect! {|s| "#{s}\n"}
      a2 = s2.split( "\n" ).collect! {|s| "#{s}\n"}
      Diff.diff(a1, a2) 
    end

    def diff( src, dst, html = true )
      diff = diff_t( src, dst )
      text = ''
      if html || true
        src = src.split("\n").collect{|s| "#{s.escapeHTML}"}
      else
        src = src.split("\n").collect{|s| "#{s}"}
      end
      si = 0
      di = 0

      diff.each do |action,position,elements|
        case action
        when :-
            while si < position
              if html
                text << "#{src[si]}\n"
              else
                text << "  #{src[si]}\n"
              end
              si += 1
              di += 1
            end
          si += elements.length
          elements.each do |l|
            if html
              text << "<del class=\"deleted\">#{l.escapeHTML.chomp}</del>\n"
            else
              text << "- #{l}"
            end
          end
        when :+
            while di < position
              if html
                text << "#{src[si]}\n"
              else
                text << "  #{src[si]}\n"
              end
              si += 1
              di += 1
            end
          di += elements.length
          elements.each do |l|
            if html
              text << "<ins class=\"added\">#{l.escapeHTML.chomp}</ins>\n"
            else
              text << "+ #{l}"
            end
          end
        end
      end
      while si < src.length
        if html
          text << "#{src[si]}\n"
        else
          text << "  #{src[si]}\n"
        end
        si += 1
      end
      text
    end

    def word_diff( src, dst, html = true )
      src_doc = Document.new( src, 'EUC-JP' )
      dst_doc = Document.new( dst, 'EUC-JP' )
      diff = compare_by_line_word( src_doc, dst_doc )
      if html
	overriding_tags = {
	  :start_common => '',
	  :end_common => '',
	  :start_del           => '<del class="deleted">',
	  :end_del             => '</del>',
	  :start_add           => '<ins class="added">',
	  :end_add             => '</ins>',
	  :start_before_change => '<del class="deleted">',
	  :end_before_change   => '</del>',
	  :start_after_change  => '<ins class="added">',
	  :end_after_change    => '</ins>',
	}
	return View.new( diff, src.encoding, src.eol ).to_html(overriding_tags, false).to_s.gsub( %r|<br />|, '' ).gsub( %r|\n</ins>|, "</ins>\n" )
      else
	return View.new( diff, src.encoding, src.eol ).to_wdiff({}, false).join.gsub( %r|\n\+\}|, "+}\n" )
      end	
    end

    def unified_diff( src, dst, unified = 3 )
      r = ''
      diff = diff_t( src, dst )
      src = src.split("\n").collect{|s| "#{s}\n"}
      si = 0
      di = 0
      sibak = nil
      dibak = nil
      diff.each do |action, position, elements|

        # difference
        case action
        when :-
          # postfix
          if unified and sibak then
            while( (si < sibak + unified) and (si < position) )
              r << "  #{src[si]}"
              si += 1
              di += 1
            end
            r << "---\n" if si < position - 1
          end
          # prefix
          while si < position
            if( (not unified) or (position - unified <= si) )
              r << "  #{src[si]}"
            end
            si += 1
            di += 1
          end
          si += elements.length
          elements.each do |l|
            r << "- #{l}"
          end
        when :+
          # postfix
          if unified and dibak then
            while( (di < dibak + unified) and (di < position) )
              r << "  #{src[si]}"
              si += 1
              di += 1
            end
            r << "---\n" if di < position - 1
          end
          # prefix
          while di < position
            if( (not unified) or (position - unified <= di) )
              r << "  #{src[si]}"
            end
            si += 1
            di += 1
          end
          di += elements.length
          elements.each do |l|
            r << "+ #{l}"
          end
        end

        # record for the next
        sibak = si
        dibak = di
      end

      # postfix
      if unified and sibak then
        while( (si < sibak + unified) and (si < src.length) )
          r << "  #{src[si]}"
          si += 1
          di += 1
        end
      elsif !r.empty?
        while si < src.length
          r << "  #{src[si]}"
          si += 1
        end
      end
      r
    end

    def redirect(cgi, url)
      head = {
               'type' => 'text/html',
             }
      print cgi.header(head)
      print %Q[
               <html>
               <head>
               <meta http-equiv="refresh" content="0;url=#{url}">
               <title>moving...</title>
               </head>
               <body>Wait or <a href="#{url}">Click here!</a></body>
               </html>]
    end

    def sendmail(subject, body)
      return unless @conf.mail || @conf.smtp_server
      Net::SMTP.start(@conf.smtp_server, 25) {|smtp|
        smtp.send_mail <<EndOfMail, @conf.mail.untaint, @conf.mail
From: #{@conf.mail_from ? @conf.mail_from : @conf.mail}
To: #{@conf.mail}
Subject: #{subject.to_jis}
Date: #{Time.now.rfc2822}
MIME-Version: 1.0
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit
X-Mailer: Hiki #{HIKI_VERSION}

#{body.to_jis}
EndOfMail
      }
    end

    def send_updating_mail(page, type, text='')
      body = <<EOS
#{'-' * 25}
REMOTE_ADDR = #{ENV['REMOTE_ADDR']}
REMOTE_HOST = #{ENV['REMOTE_HOST']}
EOS
      body << "REMOTE_USER = #{ENV['REMOTE_USER']}" if ENV['REMOTE_USER']
      body << <<EOS
        URL = #{@conf.index_url}?#{page.escape}
#{'-' * 25}
#{text}
EOS
      sendmail("[Hiki] #{type} - #{page}", body)
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

    def set_conf(conf)
      @conf = conf
    end

    def shorten(str, len = 200)
      arr = str.split(//)
      if arr.length <= len - 2
        str
      else
        arr[0...len-2].join('') + '..'
      end
    end

    def euc_to_utf8(str)
      if NKF::const_defined?(:NKF_VERSION) && NKF::NKF_VERSION >= "2.0.4"
	return NKF::nkf('-m0 -w', str)
      else
	require 'uconv'
	return Uconv.euctou8(str)
      end
    end
  
    def utf8_to_euc(str)
      if NKF::const_defined?(:NKF_VERSION) && NKF::NKF_VERSION >= "2.0.4"
	return NKF::nkf('-m0 -e', str)
      else
	require 'uconv'
	return Uconv.u8toeuc(str)
      end
    end

    def compare_by_line(doc1, doc2)
      Difference.new(doc1.split_to_line, doc2.split_to_line)
    end

    def compare_by_line_word(doc1, doc2)
      lines = compare_by_line(doc1, doc2)
      words = Difference.new
      lines.each{|line|
	if line.first == :change_elt
	  before_change = Document.new(line[1].to_s,
				       doc1.encoding, doc1.eol)
	  after_change  = Document.new(line[2].to_s,
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
