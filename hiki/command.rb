# $Id: command.rb,v 1.34 2005-02-28 12:28:56 fdiary Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'hiki/page'
require 'hiki/util'
require 'hiki/plugin'
require 'hiki/aliaswiki'
require 'hiki/session'

include Hiki::Util

module Hiki
  class Command
    def initialize(cgi, db, conf)
      @db     = db
      @params = cgi.params
      @cgi    = cgi
      @conf   = conf

      # for TrackBack
      if %r|/tb/(.+)$| =~ ENV['REQUEST_URI']
	@cgi.params['p'] = [CGI::unescape($1)]
	@cgi.params['c'] = ['plugin']
	@cgi.params['plugin'] = ['trackback_post']
      end

      @cmd    = @params['c'][0]
      @p = case @params.keys.size
           when 0
             'FrontPage'
           when 1
             @params['c'][0] ? nil : @params.keys[0]
           else
             if @cmd == "create"
               @params['key'][0] ? @params['key'][0] : nil
             else
               @params['p'][0] ? @params['p'][0] : nil
             end
           end
      @page   = Hiki::Page::new( cgi, @conf )
      @aliaswiki = AliasWiki::new( @db, @conf )

      @p = @aliaswiki.original_name(@p).to_euc if @p
      
      options = @conf.options || Hash::new( '' )
      options['page'] = @p
      options['db']   = @db
      options['cgi']  = cgi
      options['alias'] = @aliaswiki
      options['command'] = @cmd ? @cmd : 'view'
      options['params'] = @params

      @plugin = Plugin::new( options, @conf )
      @db.plugin = @plugin
      
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
          elsif @params['preview'][0]
            cmd_preview
          elsif @params['edit_form_button'][0]
            @cmd = 'edit'
            cmd_plugin(false)
            cmd_edit( @p, @plugin.text )
          end
        else
          begin
            send( "cmd_#{@cmd}" )
          rescue NameError
            if @conf.use_plugin and @plugin.plugin_command.index(@cmd) and @plugin.respond_to?(@cmd)
              @plugin.send( @cmd )
            else
              raise #"undefined command #{@cmd}"
            end
          end
        end
#      rescue Exception
#        @cmd = 'view'
#        @p = 'FrontPage'
#        cmd_view
      end
    end

  private
    def template( cmd = @cmd )
      "#{@conf.template_path }/#{@conf.template[cmd]}"
    end

    def themes
      Dir::glob("#{@conf.theme_path }/*/*.css".untaint).sort.collect {|t| File::basename(t, '.css')}
    end

    def generate_page( data )
      data[:cgi_name]   = @conf.cgi_name 
      data[:body_enter] = @body_enter
      @page.template    = template
      @page.contents    = data

      data[:last_modified] = Time::now unless data[:last_modified]
      print @page.page( @plugin )
    end

    def cmd_theme
      @conf.theme = @params['theme'][0]
      @cmd = 'view'
      dispatch
    end

    def cmd_preview
      @cmd = 'preview'
      cmd_edit( @p, @params['contents'][0], @conf.msg_preview.sanitize, @params['page_title'][0] )
    end
    
    def cmd_view
      if /^\./ =~ @p || !@db.exist?( @p )
        if !@db.exist?( @p )
          @cmd = 'create'
          cmd_create( @conf.msg_page_not_exist )
          return
        end
      end

      tokens = @db.load_cache( @p )
      unless tokens
	text = @db.load( @p )
	parser = @conf.parser::new( @conf )
	tokens = parser.parse( text )
	@db.save_cache( @p, tokens )
      end
      formatter = @conf.formatter::new( tokens, @db, @plugin, @conf )
      contents, toc = formatter.to_s, formatter.toc
      if @conf.hilight_keys
        word = @params['key'][0]
        if word && word.size > 0
          contents = hilighten(contents, word.unescape.split)
        end
      end

      @db.set_references( @p, formatter.references )
      @db.increment_hitcount( @p )
      ref = @db.get_references( @p )

      data = Hiki::Util::get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu(data, @cmd)
      
      pg_title = @plugin.page_name(@p)
      
      data[:page_title]   = (@plugin.hiki_anchor( @p.escape, @p.escapeHTML )).sanitize
      data[:view_title]   = view_title( pg_title.unescapeHTML ).sanitize
      data[:title]        = title( pg_title )
      data[:toc]          = @plugin.toc_f ? toc.sanitize : nil
      data[:body]         = formatter.apply_tdiary_theme(contents).sanitize
      data[:references]   = ref.collect! {|a| "[#{@plugin.hiki_anchor(a.escape, @plugin.page_name(a))}] " }.join.sanitize
      data[:keyword]      = @db.get_attribute(@p, :keyword).collect {|k| "[#{view_title(k)}]"}.join(' ').sanitize

      data[:last_modified]  = @db.get_last_update( @p )
      data[:page_attribute] = @plugin.page_attribute_proc.sanitize

      generate_page( data )
    end
 
    def hilighten(str, keywords)
      hilighted = str.dup
      keywords.each do |key|
        re = Regexp::new('(' << Regexp.escape(key) << ')', Regexp::IGNORECASE)
        hilighted.gsub!(/([^<]*)(<[^>]*>)?/) {
          body, tag = $1, $2
          body.gsub(re) {
            %Q[<em class="hilight">#{$1}</em>]
          } << ( tag || "" )
        }
      end
      hilighted
    end

    def cmd_index
      list = @db.page_info.sort {|a, b|
        info_a = a.values[0]
        title_a = (info_a[:title] and info_a[:title].size > 0) ? info_a[:title] : a.keys[0]
        info_b = b.values[0]
        title_b = (info_b[:title] and info_b[:title].size > 0) ? info_b[:title] : b.keys[0]
        title_a.downcase <=> title_b.downcase
      }.collect {|f|
        k = f.keys[0]
        display_text = ((f[k][:title] and f[k][:title].size > 0) ? f[k][:title] : k).escapeHTML
        display_text << " [#{@aliaswiki.aliaswiki(k)}]" if k != @aliaswiki.aliaswiki(k)
        %Q!#{@plugin.hiki_anchor(k.escape, display_text)}: #{format_date(f[k][:last_modified] )}#{@conf.msg_freeze_mark if f[k][:freeze]}!
      }

      data = Hiki::Util::get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu(data, @cmd)
      
      data[:title]     = title( @conf.msg_index )
      data[:updatelist] = list.collect! {|i| i.sanitize}
      
      generate_page( data )
    end

    def cmd_recent
      list, last_modified = get_recent
      
      data = Hiki::Util::get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu(data, @cmd)

      data[:title]      = title( @conf.msg_recent )
      data[:updatelist] = list.collect! {|i| i.sanitize}
      data[:last_modified] = last_modified

      generate_page( data )
    end

    def get_recent
      list = @db.page_info.sort {|a, b|
        k1 = a.keys[0]
        k2 = b.keys[0]
        b[k2][:last_modified] <=> a[k1][:last_modified]
      }

      last_modified = list[0].values[0][:last_modified]

      list.collect! {|f|
        k = f.keys[0]
        tm = f[k][:last_modified]
        display_text = (f[k][:title] and f[k][:title].size > 0) ? f[k][:title] : k
        display_text = display_text.escapeHTML
        display_text << " [#{@aliaswiki.aliaswiki(k)}]" if k != @aliaswiki.aliaswiki(k)
        %Q|#{format_date( tm )}: #{@plugin.hiki_anchor( k.escape, display_text )} (<a href="#{@conf.cgi_name}#{cmdstr('diff',"p=#{k.escape}")}">#{@conf.msg_diff}</a>)|
      }
      [list, last_modified]
    end

    def cmd_edit( page, text=nil, msg=nil, d_title=nil )
      page_title = d_title ? d_title.escapeHTML : @plugin.page_name(page)

      page_title = if d_title
        d_title
      else
        pg_title = @db.get_attribute(page, :title)
       ((pg_title && pg_title.size > 0) ? pg_title : page).escapeHTML
      end

      save_button = @cmd == 'edit' ? '' : nil
      preview_text = nil
      differ       = nil
      link         = nil
      formatter    = nil

      if @cmd == 'preview'
        p = @conf.parser::new( @conf ).parse( text.gsub(/\r\n/, "\n") )
        formatter = @conf.formatter::new( p, @db, @plugin, @conf )
        preview_text = formatter.to_s
        save_button = ''
      elsif @cmd == 'conflict'
	old = text.gsub(/\r/, '')
	new = @db.load( page ) || ''
	differ = word_diff( old, new ).gsub( /\n/, "<br>\n" )
        link = @plugin.hiki_anchor( page.escape, page.escapeHTML )
      end
      
      @cmd = 'edit'

      text = ( @db.load( page ) || '' ) unless text
      md5hex = @params['md5hex'][0] || @db.md5hex( page )
      
      data = Hiki::Util::get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu(data, @cmd)
      @plugin.text = text

      data[:title]          = title( page )
      data[:pagename]       = page.escapeHTML
      data[:md5hex]         = md5hex
      data[:edit_proc]      = @plugin.edit_proc.sanitize
      data[:contents]       = @plugin.text.escapeHTML
      data[:msg]            = msg
      data[:button]         = save_button
      data[:preview_button] = save_button
      data[:link]           = link
      data[:differ]         = differ ? differ.sanitize : nil
      data[:preview]        = preview_text ? formatter.apply_tdiary_theme(preview_text).sanitize :  nil
      data[:keyword]        = @db.get_attribute(page, :keyword).join("\n")
      data[:page_title]     = page_title
      
      f = @db.is_frozen?( page ) || @conf.options['freeze']
      data[:freeze]         = f ? ' checked="on"' : ''
      data[:freeze_msg]     = @conf.msg_freeze if f
      data[:form_proc]      = @plugin.form_proc.sanitize

      generate_page( data )
    end

    def cmd_diff
      old = @db.load_backup( @p ) || ''
      new = @db.load( @p ) || ''
      differ = word_diff( old, new ).gsub( /\n/, "<br>\n" )
      
      data = Hiki::Util::get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu(data, @cmd)

      data[:title]        = title("#{@p} #{@conf.msg_diff}")
      data[:differ]       = differ.sanitize
      generate_page( data )
    end

    def cmd_save( page, text, md5hex )
      pass_check = false
      if p = @params['password'][0]
        pass_check = true if @conf.password.size == 0 || p.crypt( @conf.password ) == @conf.password
      end

      subject = ''
      if text.size == 0 && pass_check
        @db.delete( page )
        @plugin.delete_proc
      else
        if @db.is_frozen?( page ) || @conf.options['freeze']
          unless pass_check
            @cmd = 'edit'
            cmd_edit( page, text )
            return
          end
        end

        title = @params['page_title'][0] ? @params['page_title'][0].strip : page
        title = title.size > 0 ? title : page

        if exist?(title)
          @cmd = 'edit'
          cmd_edit( page, text, @conf.msg_duplicate_page_title )
          return
        end
        
        if @db.save( page, text.gsub(/\r/, ''), md5hex )
          keyword = @params['keyword'][0].split("\n").collect {|k|
            k.chomp.strip}.delete_if{|k| k.size == 0}
          @db.set_attribute(page, [[:keyword, keyword.uniq],
                                   [:title, title]])
        else
          @cmd = 'conflict'
          cmd_edit( page, text, @conf.msg_save_conflict.sanitize )
          return
        end

        if pass_check 
          @db.freeze_page( page, @params['freeze'][0] ? true : false)
        end  
      end

      if text.size == 0 && pass_check
        data             = get_common_data( @db, @plugin, @conf )
        @plugin.hiki_menu(data, @cmd)

        data[:title]     = @conf.msg_delete
        data[:msg]       = @conf.msg_delete_page
        data[:link]      = page.escapeHTML
        generate_page(data)
      else
        redirect(@cgi, @plugin.hiki_url(page))
      end
    end

    def cmd_search
      word = @params['key'][0]
      if word && word.size > 0
        total, l = @db.search(word)
        if @conf.hilight_keys
          l.collect! {|p| @plugin.make_anchor("#{@conf.cgi_name}?cmd=view&p=#{p[0].escape}&key=#{word.split.join('+').escape}", @plugin.page_name(p[0])) + " - #{p[1]}"}
        else
          l.collect! {|p| @plugin.hiki_anchor( p[0].escape, @plugin.page_name(p[0])) + " - #{p[1]}"}
        end
        data             = get_common_data( @db, @plugin, @conf )
        @plugin.hiki_menu(data, @cmd)

        data[:cmd]       = 'search'
        data[:title]     = title( @conf.msg_search_result )
        data[:msg2]      = @conf.msg_search + ': '
        data[:button]    = @conf.msg_search
        data[:key]       = %Q|value="#{word.escapeHTML}"|
        word2            = word.split.join("', '")
        if l.size > 0
          data[:msg1]    = sprintf( @conf.msg_search_hits, word2.escapeHTML, total, l.size )
          data[:list]    = l.collect! {|i| i.sanitize}
        else
          data[:msg1]    = sprintf( @conf.msg_search_not_found, word2.escapeHTML )
          data[:list]    = nil
        end
      else
        data             = get_common_data( @db, @plugin, @conf )
        @plugin.hiki_menu(data, @cmd)
        data[:cmd]       = 'search'
        data[:title]     = title( @conf.msg_search )
        data[:msg1]      = @conf.msg_search_comment
        data[:msg2]      = @conf.msg_search + ': '
        data[:button]    = @conf.msg_search
        data[:key]       = 'value=""'
        data[:list]      = nil
        data[:method]  = 'get'
      end
      
      generate_page( data )
    end

    def cmd_create( msg = nil )
      p = @params['key'][0]
      if p
        @p = @aliaswiki.original_name(p).to_euc
        if /^\./ =~ @p || @p.size > @conf.max_name_size || @p.size == 0
          @params['key'][0] = nil
          cmd_create( @conf.msg_invalid_filename( @conf.max_name_size) )
          return
        end
        
        @cmd = 'edit'

        orig_page = exist?(@p)
        if orig_page or @db.exist?(@p)
          s = @db.load( @p )
          cmd_edit( orig_page || @p, s, @conf.msg_already_exist )
        else
          cmd_edit( @p, @params['text'][0] )
        end
      else
        data           = get_common_data( @db, @plugin, @conf )
        @plugin.hiki_menu(data, @cmd)
        data[:cmd]     =  'create'
        data[:title]   = title( @conf.msg_create )
        data[:msg1]    = msg
        data[:msg2]    = @conf.msg_create + ': '
        data[:button]  = @conf.msg_newpage
        data[:key]     = %Q|value="#{msg ?  @p :  ''}"|
        data[:list]    = nil
        data[:method]  = 'get'
        
        generate_page( data )
      end
    end

    def cmd_admin
      session_id = @params['session_id'][0]
      if session_id && Hiki::Session::new( @conf, session_id ).check
	admin_config( session_id )
	return
      elsif @conf.password.size > 0
	key = @params['key'][0]
	if !key || (key && key.crypt( @conf.password ) != @conf.password)
	  admin_enter_password
	  return
	end
      end
      session = Hiki::Session::new( @conf )
      admin_config( session.session_id )
    end
    
    def admin_config( session_id, msg=nil )
      data = get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu(data, @cmd)
      data[:key]            = @cgi.params['conf'][0] || 'default'

      data[:title]          = title( @conf.msg_admin )
      data[:session_id]     = session_id
      data[:site_name]      = @conf.site_name || ''
      data[:author_name]    = @conf.author_name || ''
      data[:mail]           = @conf.mail || ''
      data[:msg]            = msg
      s = @conf.mail_on_update ? :mail_on_update : :no_mail
      data[:mail_on_update] = @conf.msg_mail_on
      data[:no_mail]        = @conf.msg_mail_off

      s = @conf.use_sidebar ? :use_sidebar : :no_sidebar
      data[:use_sidebar]    = @conf.msg_use
      data[:no_sidebar]     = @conf.msg_unuse

      s = @conf.auto_link ? :use_auto_link : :no_auto_link
      data[:use_auto_link]  = @conf.msg_use
      data[:no_auto_link]   = @conf.msg_unuse

      data[:theme]          = themes.collect! do |t|
                                if @conf.theme == t
                                  [t, true]
                                else
                                  [t, false]
                                end
                              end
      data[:theme_url]      = @conf.theme_url
      data[:theme_path]     = @conf.theme_path
      data[:save_config]    = true if @cgi.params['saveconf'][0]
      generate_page( data )
    end

    def admin_enter_password
      data           = get_common_data( @db, @plugin, @conf )
      @plugin.hiki_menu(data, @cmd)

      data[:cmd]     = 'admin'
      data[:title]   = title( @conf.msg_password_title )
      data[:msg2]    = @conf.msg_password + ': '
      data[:button]  = @conf.msg_ok
      data[:key]     = 'type="password"'
      data[:list]    = nil
      data[:method]  = 'post'
      @cmd = 'password'
      generate_page( data )
    end

    def exist?( page )
      tmp = @aliaswiki.aliaswiki(page)
      if page != tmp and @p != page
        return @p
      end

      tmp =  @aliaswiki.original_name(page)
      if page != tmp and @p != tmp
      return tmp
      end

      p = (@db.select {|p| p[:title] and p[:title].unescape == page})[0]
      if p != @p and p != nil
        return p
      end
      
      if @db.exist?(page) and @p != page
        return page
      end
      
      false
    end

    def cmd_plugin(redirect_mode = true)
      return unless @conf.use_plugin
      plugin = @params['plugin'][0]

      result = true
      if @plugin.respond_to?( plugin ) && !Object.method_defined?( plugin )
        result = @plugin.send( plugin )
      else
        raise PluginException, 'not plugin method'
      end

      if redirect_mode and result
        redirect(@cgi, @plugin.hiki_url(@p))
      end
    end
  end
end
