# $Id: config.rb,v 1.6 2004-07-01 09:21:36 hitoshi Exp $
# Copyright (C) 2004 Kazuhiko <kazuhiko@fdiary.net>
#
# TADA Tadashi <sho@spc.gr.jp> holds the copyright of Config class.

HIKI_VERSION  = '0.7-devel-20040701'

module Hiki
  PATH  = "#{File::dirname(File::dirname(__FILE__))}"

  class Config
    def initialize
      load
      default
      load_cgi_conf

      instance_variables.each do |v|
        v.sub!( /@/, '' )
        instance_eval( <<-SRC
        def #{v}
          @#{v}
        end
        def #{v}=(p)
          @#{v} = p
        end
        SRC
        )
      end
    end

    def save_config
      File::open(self.config_file, "w") do |f|
        %w(site_name author_name mail theme password theme_url sidebar_class main_class theme_path mail_on_update use_sidebar auto_link).each do |c|
          case eval(c).class.to_s
          when "String"
            f.puts( %Q|@#{c} = #{eval(c).dump}| )
          when "TrueClass", "FalseClass", "NilClass"
            f.puts( %Q|@#{c} = #{eval(c).inspect}| )
          else
            raise SecurityError, "Invalid configuration"
          end
        end
      end
    end

    private
    # loading hikiconf.rb in current directory
    def load
      @secure = true unless @secure
      @options = {}
      eval( File::open( "hikiconf.rb" ){|f| f.read }.untaint, binding, "(hikiconf.rb)", 1 )
      formaterror if $data_path

      raise 'No @data_path variable.' unless @data_path
      @data_path += '/' if /\/$/ !~ @data_path

      # default values
      @index_page    ||= ''
      @smtp_server   ||= 'localhost'
      @use_plugin    ||= false
      @site_name     ||= 'hoge hoge'
      @author_name   ||= ''
      @main_on_update||= false
      @mail          ||= ''
      @theme         ||= 'hiki'
      @theme_url     ||= 'theme'
      @theme_path    ||= 'theme'
      @use_sidebar   ||= false
      @main_class    ||= 'main'
      @sidebar_class ||= 'sidebar'
      @auto_link     ||= false
      @cache_path    ||= "#{@data_path}/cache"
      @style         ||= 'default'
      @hilight_keys  ||= true
      @plugin_debug  ||= false
      @charset       ||= 'EUC-JP'
      @lang          ||= 'ja'
      @database_type ||= 'flatfile'
      @cgi_name      ||= './'
      @options         = {} unless @options.class == Hash
    end

    # loading hiki.conf in @data_path.
    def load_cgi_conf
      raise 'Do not set @data_path as same as Hiki system directory.' if @data_path == "#{PATH}/"

      variables = [:site_name, :author_name, :mail, :theme, :password,
		   :theme_url, :sidebar_class, :main_class, :theme_path,
		   :mail_on_update, :use_sidebar, :auto_link]
      begin
	cgi_conf = File::open( "#{@data_path}hiki.conf" ){|f| f.read }.untaint
	cgi_conf.gsub!( /^[@$]/, '' )
	def_vars = ''
	variables.each do |var| def_vars << "#{var} = nil\n" end
	eval( def_vars )
	Thread.start {
	  $SAFE = 4
	  eval( cgi_conf, binding, "(hiki.conf)", 1 )
	}.join
	variables.each do |var| eval "@#{var} = #{var} if #{var} != nil" end
      rescue IOError, Errno::ENOENT
      end
      formaterror if $site_name
    end

    def default
      @template_path   = "#{PATH}/template/#{@lang}"
      @plugin_path     = "#{PATH}/plugin"
      @config_file     = "#{@data_path}/hiki.conf"

      @side_menu       = 'SideMenu'
      @interwiki_name  = 'InterWikiName' 
      @aliaswiki_name  = 'AliasWikiName' 
      @formatting_rule = 'TextFormattingRules'

      # 'flat file database'
      @pages_path      = "#{@data_path}/text"
      @backup_path     = "#{@data_path}/backup"
      @info_db         = "#{@data_path}/info.db"

      @template        = {'view'    => 'view.html',
                          'index'   => 'list.html',
                          'edit'    => 'edit.html',
                          'recent'  => 'list.html',
                          'diff'    => 'diff.html',
                          'search'  => 'form.html',
                          'create'  => 'form.html',
                          'admin'   => 'adminform.html',
                          'save'    => 'success.html',
                          'password'=> 'form.html'
      }
                  
      @max_name_size   = 50 
      @password        = ''
      @generator       = "Hiki #{HIKI_VERSION}"
    end

    def method_missing( *m )
      if m.length == 1 then
        instance_eval( <<-SRC
        def #{m[0]}
          @#{m[0]}
        end
        def #{m[0]}=( p )
          @#{m[0]} = p
        end
        SRC
        )
      end
      nil
    end

    def formaterror
      raise "*** NOTICE ***\n\nThe format of configuration files (i.e. hikiconf.rb and hiki.conf) has changed.\nSee 'doc/VERSIONUP.txt' for more details.\n\n"
    end
  end
end
