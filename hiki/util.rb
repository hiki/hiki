# $Id: util.rb,v 1.3 2003-02-22 08:28:47 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'nkf'
require 'cgi'
require 'net/smtp'
require 'amrita/template'
require 'hiki/algorithm/diff'
require 'hiki/parser'
require 'hiki/html_formatter'

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

  def sanitize
    SanitizedString::new(self)
  end
end

module Hiki
  class PluginException < Exception; end

  module Util
    TOOLS = [:create, :index, :FrontPage, :search, :recent, :admin]
    CONF_S = %w($site_name $author_name $mail $theme $password)
    CONF_F = %w($mail_on_update $use_sidebar)
    
    def csv_split( source, delimiter = ',' )
      status = :IN_FIELD
      csv = []
      csv.push (last = "")
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
      "<strong>#{e.class}(#{e.message}): #{method.escapeHTML}</strong><br>"
    end

    def save_config
      File::open($config_file, "w") do |f|
        CONF_S.each do |c|
          f.puts( %Q|#{c} = "#{eval(c)}"| ) if c
        end
        CONF_F.each do |c|
          f.puts( "#{c} = #{eval(c)}" )
        end
      end
    end

    def load_config
      begin
        conf = File::readlines( $config_file ).join
        eval( conf.untaint )
      rescue
      end
    end

    def cmdhref( cmd, page )
      "#{$cgi_name }?c=#{cmd};p=#{page.escape}"
    end

    def cmdstr( cmd, param )
      "#{$cgi_name }?c=#{cmd};#{param}"
    end

    def anchor( page )
      "<a href=\"#{$cgi_name}?#{page.escape}\">#{page.escapeHTML}</a>"
    end

    def title( s )
      "#{$site_name.escapeHTML} - #{s}"
    end

    def view_title( s )
      t = %Q!<a href="#{ cmdstr('search', "key=#{s.escape}") }">#{s.escapeHTML}</a>!
#      "#{$site_name.escapeHTML} - #{t}"
    end

    def make_link( links )
      s = ''
      links.each do |l|
        s << "[#{anchor( l )}] "
      end
      s
    end

    def format_date( tm )
      tm.strftime(msg_time_format).sub(/#DAY#/, "(#{msg_day[tm.wday]})")
    end

    def tools
      h = Hash::new
      TOOLS.each do |i|
        cmd = (i == :FrontPage) ? '' : 'c='
        h[i] = a(:href=>"#{$cgi_name }?#{cmd}#{i.to_s}")
      end
      h
    end

    def get_common_data( db, plugin )
      data = Hash::new
      data[:version]     = HIKI_VERSION
      data[:ruby_ver]    = "Ruby #{RUBY_VERSION}"
      data[:amrita_ver]  = "Amrita"
      data[:generator]   = "Hiki #{HIKI_VERSION}"
      data[:tools]       = tools
      data[:author_name] = $author_name
      data[:view_style]  = $use_sidebar ? 'main' : 'hiki' # for tDiary theme
      if $use_sidebar
        parser = Parser::new
        m = db.load( $side_menu ) || ''
        t = parser.parse( m )
        f = HTMLFormatter::new( t, db, plugin, 's' )
        data[:sidebar] = {:menu => f.to_s.sanitize}
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
    
    def sendmail(subject, body)
      return unless $mail || $smtp_server
      Net::SMTP.start($smtp_server, 25) {|smtp|
        smtp.send_mail <<EndOfMail, $mail, $mail
From: #{$mail}
To: #{$mail}
Subject: #{subject.to_jis}
Date: #{Time.now.rfc2822}

-------------------------
REMOTE_ADDR = #{ENV['REMOTE_ADDR']}
REMOTE_HOST = #{ENV['REMOTE_HOST']}
#{body.to_jis}
EndOfMail
      }
    end
  end
end
