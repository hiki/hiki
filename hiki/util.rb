# $Id: util.rb,v 1.9 2004-06-10 14:37:45 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'nkf'
require 'cgi'
require 'net/smtp'
require 'amrita/template'
require 'hiki/algorithm/diff'
require "style/#{$style}/parser"
require "hiki/hiki_formatter"

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
      msg << "<strong>#{e.backtrace.join("<br>\n")}</strong>" if $plugin_debug
      msg
    end

    def save_config
      File::open($config_file, "w") do |f|
        %w($site_name $author_name $mail $theme $password $theme_url $sidebar_class $main_class $theme_path $mail_on_update $use_sidebar $auto_link).each do |c|
          f.puts( %Q|#{c} = #{eval(c).inspect}| ) if c
        end
      end
    end

    def load_config
      begin
        conf = File::readlines( $config_file ).join
        eval( conf.untaint, binding, $config_file, 1 )
      rescue
      end
    end

    def cmdstr( cmd, param )
      "?c=#{cmd};#{param}"
    end

    def title( s )
      "#{$site_name.escapeHTML} - #{s}"
    end

    def view_title( s )
      %Q!<a href="#{$cgi_name}#{cmdstr('search', "key=#{s.escape}") }">#{s.escapeHTML}</a>!
    end

    def format_date( tm )
      tm.strftime(msg_time_format).sub(/#DAY#/, "(#{msg_day[tm.wday]})")
    end

    def get_common_data( db, plugin )
      data = Hash::new
      $generator         = "Hiki #{HIKI_VERSION}"
      data[:author_name] = $author_name
      data[:view_style]  = $use_sidebar ? $main_class : 'hiki' # for tDiary theme
      data[:cgi_name]    = $cgi_name
      if $use_sidebar
        parser = Parser::new
        m = db.load( $side_menu ) || ''
        t = parser.parse( m )
        f = HikiFormatter::new( t, db, plugin, 's' )
        data[:sidebar]   =  {:menu => f.to_s.sanitize}
        data[:main_class]    = $main_class
        data[:sidebar_class] = $sidebar_class
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
      return unless $mail || $smtp_server
      Net::SMTP.start($smtp_server, 25) {|smtp|
        smtp.send_mail <<EndOfMail, $mail, $mail
From: #{$mail_from ? $mail_from : $mail}
To: #{$mail}
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
        URL = #{$index_page}?#{page.escape}
#{'-' * 25}
#{text}
EOS
    end

    def theme_url
      if /\.css\Z/i =~ $theme_url
        $theme_url
      else
       "#{$theme_url}/#{$theme}/#{$theme}.css"
      end
    end

    def base_css_url
      if /\.css\Z/i =~ $theme_url
        "#{File.dirname($theme_url)}/../hiki_base.css"
      else
       "#{$theme_url}/hiki_base.css"
      end
    end
  end
end
