# $Id: util.rb,v 1.12 2004-08-31 07:25:46 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'nkf'
require 'cgi'
require 'net/smtp'
require 'amrita/template'
require 'hiki/algorithm/diff'

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
      tm.strftime(msg_time_format).sub(/#DAY#/, "(#{msg_day[tm.wday]})")
    end

    def get_common_data( db, plugin, conf )
      data = Hash::new
      data[:author_name] = conf.author_name
      data[:view_style]  = conf.use_sidebar ? conf.main_class : 'hiki' # for tDiary theme
      data[:cgi_name]    = conf.cgi_name
      if conf.use_sidebar
        parser = eval( conf.parser )::new( conf )
        m = db.load( conf.side_menu ) || ''
        t = parser.parse( m )
        f = eval( conf.formatter )::new( t, db, plugin, conf, 's' )
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
X-Mailer: Hiki #{HIKI_VERSION}

#{body.to_jis}
EndOfMail
      }
    end

    def send_updating_mail(page, type, text='')
      sendmail("[Hiki] #{type} - #{page}", <<EOS)
#{'-' * 25}
REMOTE_ADDR = #{ENV['REMOTE_ADDR']}
REMOTE_HOST = #{ENV['REMOTE_HOST']}
        URL = #{@conf.index_page}?#{page.escape}
#{'-' * 25}
#{text}
EOS
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
  end
end
