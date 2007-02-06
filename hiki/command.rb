# $Id: command.rb,v 1.88 2007-02-06 10:42:13 fdiary Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'timeout'
require 'hiki/page'
require 'hiki/util'
require 'hiki/plugin'
require 'hiki/aliaswiki'
require 'hiki/session'

include Hiki::Util

module Hiki
  class PermissionError < StandardError; end

  class Command
    def initialize(cgi, db, conf)
      @db     = db
      @params = cgi.params
      @cgi    = cgi
      @conf   = conf
      code_conv

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
             @cmd ? nil : @params.keys[0]
           else
             if @cmd == "create"
               @params['key'][0] ? @params['key'][0] : nil
             else
               @params['p'][0] ? @params['p'][0] : nil
             end
           end

      if /\A\.{1,2}\z/ =~ @p
        redirect(@cgi, @conf.index_url)
        return
      end

      @aliaswiki  = AliasWiki::new( @db.load( @conf.aliaswiki_name ) )
      @p = @aliaswiki.original_name(@p).to_euc if @p

      options = @conf.options || Hash::new( '' )
      options['page'] = @p
      options['db']   = @db
      options['cgi']  = cgi
      options['alias'] = @aliaswiki
      options['command'] = @cmd ? @cmd : 'view'
      options['params'] = @params

      @plugin = Plugin::new( options, @conf )
      session_id = @cgi.cookies['session_id'][0]
      if session_id
        session = Hiki::Session::new( @conf, session_id )
        if session.check
          @plugin.user = session.user
          @plugin.session_id = session_id
        end
      end
      if @conf.use_session && !@plugin.session_id
        session = Hiki::Session::new( @conf )
        session.save
        @plugin.session_id = session.session_id
        @plugin.add_cookie( session_cookie( @plugin.session_id ))
      end
      @body_enter = @plugin.body_enter_proc
    end

    def dispatch
      begin
        Timeout.timeout(@conf.timeout) {
          if 'POST' == @cgi.request_method
            raise PermissionError, 'Permission denied' unless @plugin.postable?
          end
          @cmd = 'view' unless @cmd
          raise if !@p && ['view', 'edit', 'diff', 'save'].index( @cmd )
          if @cmd == 'edit'
            raise PermissionError, 'Permission denied' unless @plugin.editable?
            cmd_edit( @p )
          elsif @cmd == 'save'
            raise PermissionError, 'Permission denied' unless @plugin.editable?
            if @params['save'][0]
              cmd_save(@p, @params['contents'][0], @params['md5hex'][0], @params['update_timestamp'][0])
            elsif @params['edit_form_button'][0]
              @cmd = 'edit'
              cmd_plugin(false)
              cmd_edit( @p, @plugin.text )
            else
              cmd_preview
            end
          elsif @cmd == 'create'
            raise PermissionError, 'Permission denied' unless @plugin.editable?
            send( "cmd_#{@cmd}" )
          else
            if @conf.use_plugin and @plugin.plugin_command.index(@cmd) and @plugin.respond_to?(@cmd)
              @plugin.send( @cmd )
            else
              send( "cmd_#{@cmd}" )
            end
          end
        }
      rescue NoMethodError, PermissionError, Timeout::Error
        data = get_common_data( @db, @plugin, @conf )
        data[:message] = CGI::escapeHTML( $!.message )
        generate_error_page( data )
      end
    end

  private
    def generate_page( data, status = 'OK' )
      @plugin.hiki_menu(data, @cmd)
      @plugin.title = data[:title]
      data[:cmd] = @cmd
      data[:cgi_name] = @conf.cgi_name
      data[:body_enter] = @body_enter
      data[:lang] = @conf.lang
      data[:header] = @plugin.header_proc
      data[:body_leave] = @plugin.body_leave_proc
      data[:page_attribute] ||= ''
      data[:footer] = @plugin.footer_proc
      data.update( @plugin.data ) if @plugin.data
      if data[:toc]
        data[:body] = data[:toc] + data[:body] if @plugin.toc_f == :top
        data[:body].gsub!( Regexp.new( Regexp.quote( Plugin::TOC_STRING ) ), data[:toc] )
      end

      @page = Hiki::Page::new( @cgi, @conf )
      @page.template = @conf.read_template( @cmd )
      @page.contents = data

      data[:last_modified] = Time::now unless data[:last_modified]
      @page.process( @plugin )
      @page.out( 'status' => status )
    end

    def generate_error_page( data )
      @plugin.hiki_menu(data, @cmd)
      @plugin.title = title( 'Error' )
      data[:cgi_name] = @conf.cgi_name
      data[:view_title] = 'Error'
      data[:header] = @plugin.header_proc
      data[:frontpage] = @plugin.page_name( 'FrontPage' )
      @page = Hiki::Page::new( @cgi, @conf )
      @page.template = @conf.read_template( 'error' )
      @page.contents = data
      @page.process( @plugin )
      @page.out( 'status' => 'NOT_FOUND' )
    end

    def cmd_preview
      raise PermissionError if @plugin.session_id && @plugin.session_id != @cgi['session_id']
      @cmd = 'preview'
      cmd_edit( @p, @params['contents'][0], @conf.msg_preview, @params['page_title'][0] )
    end

    def cmd_view
      unless @db.exist?( @p )
        @cmd = 'create'
        cmd_create( @conf.msg_page_not_exist )
        return
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

      old_ref = @db.get_attribute( @p, :references )
      new_ref = formatter.references 
      @db.set_references( @p, new_ref ) if new_ref != old_ref
      ref = @db.get_references( @p )

      data = get_common_data( @db, @plugin, @conf )

      pg_title = @plugin.page_name(@p)

      data[:page_title]   = (@plugin.hiki_anchor( @p.escape, @p.escapeHTML ))
      data[:view_title]   = pg_title
      data[:title]        = title( pg_title.unescapeHTML )
      data[:toc]          = @plugin.toc_f ? toc : nil
      data[:body]         = formatter.apply_tdiary_theme(contents)
      data[:references]   = ref.collect! {|a| "[#{@plugin.hiki_anchor(a.escape, @plugin.page_name(a))}] " }.join
      data[:keyword]      = @db.get_attribute(@p, :keyword).collect {|k| "[#{view_title(k)}]"}.join(' ')

      data[:last_modified]  = @db.get_last_update( @p )
      data[:page_attribute] = @plugin.page_attribute_proc

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
      list = @db.page_info.sort_by {|e|
        k,v = e.to_a.first
        if v[:title] && !v[:title].empty?
          v[:title].downcase
        else
          k.downcase
        end
      }.collect {|f|
        k = f.keys[0]
        editor = f[k][:editor] ? "by #{f[k][:editor]}" : ''
        display_text = ((f[k][:title] and f[k][:title].size > 0) ? f[k][:title] : k).escapeHTML
        display_text << " [#{@aliaswiki.aliaswiki(k)}]" if k != @aliaswiki.aliaswiki(k)
        %Q!#{@plugin.hiki_anchor(k.escape, display_text)}: #{format_date(f[k][:last_modified] )} #{editor}#{@conf.msg_freeze_mark if f[k][:freeze]}!
      }

      data = get_common_data( @db, @plugin, @conf )

      data[:title]     = title( @conf.msg_index )
      data[:updatelist] = list

      generate_page( data )
    end

    def cmd_recent
      list, last_modified = get_recent

      data = get_common_data( @db, @plugin, @conf )

      data[:title]      = title( @conf.msg_recent )
      data[:updatelist] = list
      data[:last_modified] = last_modified

      generate_page( data )
    end

    def get_recent
      list = @db.page_info.sort_by {|e|
        k,v = e.to_a.first
        v[:last_modified]
      }.reverse

      last_modified = list[0].values[0][:last_modified]

      list.collect! {|f|
        k = f.keys[0]
        tm = f[k][:last_modified]
        editor = f[k][:editor] ? "by #{f[k][:editor]}" : ''
        display_text = (f[k][:title] and f[k][:title].size > 0) ? f[k][:title] : k
        display_text = display_text.escapeHTML
        display_text << " [#{@aliaswiki.aliaswiki(k)}]" if k != @aliaswiki.aliaswiki(k)
        %Q|#{format_date( tm )}: #{@plugin.hiki_anchor( k.escape, display_text )} #{editor.escapeHTML} (<a href="#{@conf.cgi_name}#{cmdstr('diff',"p=#{k.escape}")}">#{@conf.msg_diff}</a>)|
      }
      [list, last_modified]
    end

    def cmd_edit( page, text=nil, msg=nil, d_title=nil )
      page_title = d_title ? d_title.escapeHTML : @plugin.page_name(page)

      save_button = @cmd == 'edit' ? '' : nil
      preview_text = nil
      differ       = nil
      link         = nil
      formatter    = nil
      data = get_common_data( @db, @plugin, @conf )
      if @db.is_frozen?( page ) || @conf.options['freeze']
        data[:freeze] = ' checked'
      else
        data[:freeze] = ''
      end

      if @cmd == 'preview'
        p = @conf.parser::new( @conf ).parse( text.gsub(/\r/, '') )
        formatter = @conf.formatter::new( p, @db, @plugin, @conf )
        preview_text, toc = formatter.to_s, formatter.toc
        save_button = ''
        data[:keyword] = CGI.escapeHTML( @params['keyword'][0] || '' )
        data[:update_timestamp] = @params['update_timestamp'][0] ? ' checked' : ''
        data[:freeze] = @params['freeze'][0] ? ' checked' : ''
      elsif @cmd == 'conflict'
        old = text.gsub(/\r/, '')
        new = @db.load( page ) || ''
        differ = word_diff( old, new ).gsub( /\n/, "<br>\n" )
        link = @plugin.hiki_anchor( page.escape, page.escapeHTML )
      end

      @cmd = 'edit'

      if rev = @params['r'][0]
        text = @conf.repos.get_revision(page, rev.to_i)
        raise 'No such revision.' if text.empty?
      else
        text = ( @db.load( page ) || '' ) unless text
      end
      md5hex = @params['md5hex'][0] || @db.md5hex( page )

      @plugin.text = text

      data[:title]          = title( page )
      data[:toc]            = @plugin.toc_f ? toc : nil
      data[:pagename]       = page.escapeHTML
      data[:md5hex]         = md5hex
      data[:edit_proc]      = @plugin.edit_proc
      data[:contents]       = @plugin.text.escapeHTML
      data[:msg]            = msg
      data[:button]         = save_button
      data[:preview_button] = save_button
      data[:link]           = link
      data[:differ]         = differ
      data[:body]        = preview_text ? formatter.apply_tdiary_theme(preview_text) :  nil
      data[:keyword]        ||= CGI.escapeHTML( @db.get_attribute(page, :keyword).join("\n") )
      data[:update_timestamp] ||= ' checked'
      data[:page_title]     = page_title
      data[:form_proc]      = @plugin.form_proc
      data[:session_id]     = @plugin.session_id

      generate_page( data )
    end

    def cmd_diff
      old = @db.load_backup( @p ) || ''
      new = @db.load( @p ) || ''
      differ = word_diff( old, new ).gsub( /\n/, "<br>\n" )

      data = get_common_data( @db, @plugin, @conf )

      data[:title]        = title("#{@p} #{@conf.msg_diff}")
      data[:differ]       = differ
      generate_page( data )
    end

    def cmd_save( page, text, md5hex, update_timestamp = true )
      raise PermissionError if @plugin.session_id && @plugin.session_id != @cgi['session_id']
      subject = ''
      if text.empty?
        @db.delete( page )
        @plugin.delete_proc
        data             = get_common_data( @db, @plugin, @conf )
        data[:title]     = @conf.msg_delete
        data[:msg]       = @conf.msg_delete_page
        data[:link]      = page.escapeHTML
        generate_page(data)
      else
        title = @params['page_title'][0] ? @params['page_title'][0].strip : page
        title = title.size > 0 ? title : page

        if exist?(title)
          @cmd = 'edit'
          cmd_edit( page, text, @conf.msg_duplicate_page_title )
          return
        end

        if @plugin.save( page, text, md5hex, update_timestamp )
          keyword = @params['keyword'][0].split("\n").collect {|k|
            k.chomp.strip}.delete_if{|k| k.size == 0}
          attr = [[:keyword, keyword.uniq], [:title, title]]
          attr << [:editor, @plugin.user]
          @db.set_attribute(page, attr)
        else
          @cmd = 'conflict'
          cmd_edit( page, text, @conf.msg_save_conflict )
          return
        end

        @db.freeze_page( page, @params['freeze'][0] ? true : false) if @plugin.admin?
        redirect(@cgi, @conf.base_url + @plugin.hiki_url(page))
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
        data[:title]     = title( @conf.msg_search_result )
        data[:msg2]      = @conf.msg_search + ': '
        data[:button]    = @conf.msg_search
        data[:key]       = %Q|value="#{word.escapeHTML}"|
        word2            = word.split.join("', '")
        if l.size > 0
          data[:msg1]    = sprintf( @conf.msg_search_hits, word2.escapeHTML, total, l.size )
          data[:list]    = l
        else
          data[:msg1]    = sprintf( @conf.msg_search_not_found, word2.escapeHTML )
          data[:list]    = nil
        end
      else
        data             = get_common_data( @db, @plugin, @conf )
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
        data[:title]   = title( @conf.msg_create )
        data[:msg1]    = msg
        data[:msg2]    = @conf.msg_create + ': '
        data[:button]  = @conf.msg_newpage
        data[:key]     = %Q|value="#{msg ?  @p.escapeHTML :  ''}"|
        data[:list]    = nil
        data[:method]  = 'get'

        generate_page( data )
      end
    end

    def cmd_login
      name = @params['name'][0]
      password = @params['password'][0]
      page = @params['p'][0]
      msg_login_result = nil
      status = 'OK'
      if name && password
        session = Hiki::Session::new( @conf )
        @plugin.login( name, password )

        if @plugin.user
          session.user = @plugin.user
          session.save
          if page && !page.empty?
            redirect(@cgi, @conf.base_url + @plugin.hiki_url( page ), session_cookie( session.session_id ))
          else
            redirect(@cgi, @conf.index_url, session_cookie( session.session_id ))
          end
          return
        else
          msg_login_result = @conf.msg_login_failure
          status = '403 Forbidden'
        end
      end

      data = get_common_data( @db, @plugin, @conf )
      data[:title]   = title( @conf.msg_login )
      data[:button]  = @conf.msg_ok
      data[:login_result] = msg_login_result
      data[:page] = ( page || '' ).escapeHTML
      generate_page( data, status )
    end

    def cmd_admin
      raise PermissionError, 'Permission denied' unless @plugin.admin?

      data = get_common_data( @db, @plugin, @conf )
      data[:key]            = @cgi.params['conf'][0] || 'default'

      data[:title]          = title( @conf.msg_admin )
      data[:session_id]     = @plugin.session_id
      if @cgi.params['saveconf'][0]
        raise PermissionError if @plugin.session_id && @plugin.session_id != @cgi['session_id']
        data[:save_config]    = true
      end
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
        redirect(@cgi, @conf.base_url + @plugin.hiki_url(@p))
      end
    end

    def cmd_logout
      if session_id = @cgi.cookies['session_id'][0]
        cookies = [session_cookie(session_id, -1)]
        Hiki::Session::new( @conf, session_id ).delete
      end
      redirect(@cgi, @conf.index_url, cookies)
    end

    def cookie(name, value, max_age = Session::MAX_AGE)
      CGI::Cookie::new( {
                          'name' => name,
                          'value' => value,
                          'path' => @plugin.cookie_path,
                          'expires' => Time::now.gmtime + max_age
                        } )
    end

    def session_cookie(session_id, max_age = Session::MAX_AGE)
      cookie('session_id', session_id, max_age)
    end

    def code_conv
      if @conf.mobile_agent? && /EUC-JP/i =~ @conf.charset
        @params.each_key do |k|
          @params[k].each do |v|
            v.replace(v.to_euc) if v
          end
        end
      end
    end
  end
end
