# $Id: command.rb,v 1.3 2003-02-23 02:20:08 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'amrita/template'

require 'hiki/page'
require 'hiki/util'
require 'hiki/plugin'
require 'hiki/parser'
require 'hiki/html_formatter'
require "messages/#{$lang}"

include Amrita
include Hiki::Util
include Hiki::Messages

module Hiki
  class Command
    def initialize(cgi, db)
      @db     = db
      @params = cgi.params
      @cmd    = @params['c'][0]
      @p = case @params.keys.size
           when 0
             'FrontPage'
           when 1
             @params['c'][0] ? nil : @params.keys[0]
           else
             @params['p'][0] ? @params['p'][0] : nil
           end
      @p = @p.unescape.to_euc if @p
      
      @page   = Hiki::Page::new( cgi )
      options = $options || Hash.new( '' )
      
      options['page'] = @p
      options['db']   = @db
      options['cgi']  = cgi

      @plugin = Plugin::new( options )
      load_plugin( @plugin )
      @body_enter = @plugin.body_enter_proc.sanitize
    end

    def dispatch
      @cmd = 'view' unless @cmd
      begin
        raise if !@p && ['view', 'edit', 'diff', 'save'].index( @cmd )
        case @cmd
        when 'edit'
          cmd_edit( @p )
        when 'save'
          if @params['save'][0]
            cmd_save(@p, @params['contents'][0], @params['md5hex'][0] )
          else
            cmd_preview
          end
        else
          send( "cmd_#{@cmd}" )
        end
#      rescue Exception
#        @cmd = 'view'
#        @p = 'FrontPage'
#        cmd_view
      end
    end

  private
    def template( cmd = @cmd )
      "#{$template_path }/#{$template[cmd]}"
    end

    def theme_css
      "#{$theme_path }/#{$theme}/#{$theme}.css"
    end

    def themes
      Dir::glob("#{$theme_path }/*/*.css").sort.collect {|t| File::basename(t, '.css')}
    end
    
    def generate_page( data )
      data[:stylesheet] = theme_css
      data[:cgi_name]   = $cgi_name 
      data[:body_enter] = @body_enter
      @page.template    = template
      @page.contents    = data

      last_update = @cmd == 'view' ? @db.get_last_update( @p ) : Time::now
      print @page.page( @plugin, last_update )
    end

    def cmd_theme
      $theme = @params['theme'][0]
      @cmd = 'view'
      dispatch
    end

    def cmd_preview
      @cmd = 'preview'
      cmd_edit( @p, @params['contents'][0], msg_preview.sanitize )
    end
    
    def cmd_view
      if /^\./ =~ @p || !@db.exist?( @p )
        @cmd = 'create'
        cmd_create( msg_page_not_exist )
        return
      end
      
      html = nil
      text = @db.load( @p )
      
      parser = Parser::new
      tokens = parser.parse( text )
      formatter = HTMLFormatter::new( tokens, @db, @plugin )
      contents, toc = formatter.to_s, formatter.toc

      @db.set_references ( @p, formatter.references )
      @db.increment_hitcount ( @p )
      ref = @db.get_references( @p )
      
      data = Hiki::Util::get_common_data( @db, @plugin )
      data[:view_title]   = view_title( @p ).sanitize
      data[:title]        = title ( @p )
      data[:tools][:edit] = a( :href=> cmdhref( 'edit', @p ) )
      data[:tools][:diff] = a( :href=> cmdhref( 'diff', @p ) )
      data[:toc]          = toc.sanitize if @plugin.toc_f
      data[:body]         = contents.sanitize
      data[:references]   = ref.collect! {|a| "[#{anchor(a)}] " }.join.sanitize

      tm = @db.get_last_update( @p )
      data[:modified]     = format_date( tm )

      generate_page( data )
    end

    def cmd_index
      list = @db.page_info.sort {|a, b| a.keys[0] <=> b.keys[0]}.collect! do |f|
        k = f.keys[0]
        %Q!#{anchor(k)}: #{format_date(f[k][:last_modified] )}#{msg_freeze_mark if f[k][:freeze]}!
      end

      data = Hiki::Util::get_common_data( @db, @plugin )
      data[:title]     = title( msg_index )
      data[:updatelist] = list.collect! {|i| i.sanitize}
      
      generate_page( data )
    end

    def cmd_recent
      list = get_recent
      
      data = Hiki::Util::get_common_data( @db, @plugin )
      data[:title]      = title( msg_recent )
      data[:updatelist] = list.collect! {|i| i.sanitize}
      
      generate_page( data )
    end

    def get_recent
      list = @db.page_info.sort do |a, b|
        k1 = a.keys[0]
        k2 = b.keys[0]
        b[k2][:last_modified] <=> a[k1][:last_modified]
      end.collect! do |f|
        k = f.keys[0]
        tm = f[k][:last_modified]
        "#{format_date( tm )}: #{anchor( k )}"
      end
    end

    def cmd_edit( page, text=nil, msg=nil )
      save_button = (@cmd == 'edit') ? '' : nil
      preview_text = differ = link = nil
      tokens = Hiki::Parser::new.parse( @db.load( $formatting_rule ) )
      format_text = Hiki::HTMLFormatter::new( tokens, @db, @plugin ).to_s

      if @cmd == 'preview'
        p = Hiki::Parser::new.parse( text )
        preview_text = Hiki::HTMLFormatter::new( p, @db, @plugin ).to_s
        save_button = ''
        @cmd = 'edit'
      elsif @cmd == 'conflict'
        t = @db.load( page ) || ''
        d = diff_t( t, text.gsub!(/\r/, '') )
        differ = HTMLFormatter::diff ( d )
        link = anchor( page )
        @cmd = 'edit'
      end

      text = ( @db.load( page ) || '' ) unless text
      md5hex = @params['md5hex'][0] || @db.md5hex( page )
      
      data = Hiki::Util::get_common_data( @db, @plugin )
      data[:title]          = title( page.escapeHTML )
      data[:tools][:edit]   = a( :href=> cmdhref( 'edit', @p ) )
      data[:tools][:diff]   = a( :href=> cmdhref( 'diff', @p ) )
      data[:pagename]       = a( :value => page.escape )
      data[:md5hex]         = a( :value => md5hex )
      data[:contents]       = text
      data[:msg]            = msg
      data[:button]         = save_button
      data[:preview_button] = save_button
      data[:format]         = format_text.sanitize
      data[:link]           = link ? {:p => link.sanitize} : nil
      data[:differ]         = differ ? differ.sanitize : nil
      data[:preview]        = preview_text ? preview_text.sanitize :  nil
      f = @db.is_frozen?( page )
      data[:freeze]         = a(:checked => f ? 'on': nil)
      data[:freeze_msg]     = msg_freeze if f
      
      generate_page( data )
    end

    def cmd_diff
      diff = @db.diff( @p )
      differ = diff ? HTMLFormatter::diff( diff ) : msg_no_recent
      
      data = Hiki::Util::get_common_data( @db, @plugin )
      data[:title]        = title("#{@p.escapeHTML} #{msg_diff}")
      data[:tools][:edit] = a(:href=> cmdhref( 'edit', @p ))
      data[:tools][:diff] = a(:href=> cmdhref( 'diff', @p ))
      data[:differ]       = differ.sanitize
      generate_page( data )
    end

    def cmd_save( page, text, md5hex )
      last_text = @db.load( page ) || ''

      pass_check = false
      if p = @params['password'][0]
        pass_check = true if $password.size == 0 || p.crypt( $password ) == $password
      end

      if @db.is_frozen?( page )
        unless pass_check
          @cmd = 'edit'
          cmd_edit( page, text )
          return
        end
      end
        
      unless @db.save( page, text.gsub(/\r/, ''), md5hex )
        @cmd = 'conflict'
        cmd_edit( page, text, msg_save_conflict.sanitize )
        return
      end
      
      if pass_check 
        @db.freeze_page( page, @params['freeze'][0] ? true : false)
      end  

      @db.set_last_update( page, Time::now )
      
      begin
        Hiki::Util::sendmail("[Hiki] update - #{page}",
                 "#{'-' * 25}\n#{last_text}\n#{'-' * 25}\n#{text}") if $mail_on_update
      rescue
      end

      data             = get_common_data( @db, @plugin )
      data[:title]     = msg_thanks
      data[:msg]       = msg_thanks
      data[:link]      = anchor(page).sanitize

      generate_page(data)
      
    end

    def cmd_search
      word = @params['key'][0]
      if word && word.size > 0
        total, l = @db.search(word)
        l.collect! {|p| anchor( p )}
        data             = get_common_data( @db, @plugin )
        data[:cmd]       = a( :value => 'search' )
        data[:title]     = title( msg_search_result )
        data[:msg2]      = msg_search + ': '
        data[:button]    = a( :value =>msg_search )
        data[:key]       = a( :value => word )
        if l.size > 0
          data[:msg1]    = sprintf( msg_search_hits, word.escapeHTML, total, l.size )
          data[:list]    = {:listitem => l.collect! {|i| i.sanitize}}
        else
          data[:msg1]    = sprintf( msg_search_not_found, word.escapeHTML )
          data[:list]    = nil
        end
      else
        data             = get_common_data( @db, @plugin )
        data[:cmd]       = a( :value => 'search' )
        data[:title]     = title( msg_search )
        data[:tools]     = tools
        data[:msg1]      = msg_search_comment
        data[:msg2]      = msg_search + ': '
        data[:button]    = a( :value => msg_search )
        data[:key]       = a( :value => '' )
        data[:list]      = nil
        data[:method]  = 'get'
      end
      
      generate_page( data )
    end

    def cmd_create( msg = nil )
      p = @params['key'][0]
      if p
        @p = p.unescape.to_euc
        if /^\./ =~ @p || @p.size > $max_name_size
          @params['key'][0] = nil
          cmd_create( msg_invalid_filename( $max_name_size) )
          return
        end
        
        @cmd = 'edit'
        unless @db.exist? ( @p )
          @db.touch( @p )
          cmd_edit( @p )
        else
          s = @db.load ( @p )
          cmd_edit( @p, s, msg_already_exist )
        end
      else
        data           = get_common_data( @db, @plugin )
        data[:cmd]     = a( :value => 'create' )
        data[:title]   = title( msg_create )
        data[:msg1]    = msg
        data[:msg2]    = msg_create + ': '
        data[:button]  = a( :value => msg_newpage )
        data[:key]     = msg ? a( :value => @p ) : a( :value => '' )
        data[:list]    = nil
        data[:method]  = 'get'
        
        generate_page( data )
      end
    end

    def cmd_admin
      if @params['saveconf'][0]
          admin_save_config
      else
        if $password.size > 0
          key = @params['key'][0]
          if !key || (key && key.crypt( $password ) != $password)
            admin_enter_password
            return
          end
        end
        admin_config
      end
    end

    def admin_config( msg=nil )
      data = get_common_data( @db, @plugin )
      data[:site_name]      = $site_name || ''
      data[:author_name]    = $author_name || ''
      data[:mail]           = $mail || ''
      data[:msg]            = msg
      s = $mail_on_update ? :mail_on_update : :no_mail
      data[:mail_on_update] = msg_mail_on
      data[:no_mail]        = msg_mail_off
      data[s]               = a( :selected => "selected" )

      s = $use_sidebar ? :use_sidebar : :no_sidebar
      data[:use_sidebar]    = msg_use
      data[:no_sidebar]     = msg_unuse
      data[s]               = a( :selected => "selected" )

      data[:theme]          = themes.collect! do |t|
                                if $theme == t
                                  a(:value => t, :selected => "selected") {t}
                                else
                                  a(:value => t) {t}
                                end
                              end
      generate_page( data )
    end

    def admin_enter_password
      data           = get_common_data( @db, @plugin )
      data[:cmd]     = a( :value => 'admin' )
      data[:title]   = title( msg_password_title )
      data[:msg2]    = msg_password + ': '
      data[:button]  = a( :value => msg_ok )
      data[:key]     = a( :type  => 'password' )
      data[:list]    = nil
      data[:method]  = 'post'
      @cmd = 'password'
      generate_page( data )
    end

    def admin_save_config
      $site_name      = @params['site_name'][0]
      $author_name    = @params['author_name'][0]
      $mail           = @params['mail'][0]
      old_password    = @params['old_password'][0]
      password1       = @params['password1'][0]
      password2       = @params['password2'][0]
      $mail_on_update = @params['mail_on_update'][0] == "true"
      $theme          = @params['theme'][0]
      $use_sidebar    = @params['sidebar'][0] == "true"

      if password1.size > 0
        if ($password.size > 0 && old_password.crypt( $password ) != $password) ||
           (password1 != password2)
          admin_config( msg_invalid_password )
          return
        end
        salt = [rand(64),rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
        $password = password1.crypt( salt )
      end
      save_config
      admin_config( msg_save_config )
    end

    def load_plugin( plugin )
      return unless $use_plugin

      Dir::glob("#{$plugin_path}/*.rb" ).sort.each do |f|
        plugin_file = f.untaint
        open( plugin_file ) do |src|
          plugin.instance_eval( src.read.untaint )
        end
      end
    end
  end
end
