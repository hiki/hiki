# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2004-2005 Kazuhiko <kazuhiko@fdiary.net>
#
# TADA Tadashi <sho@spc.gr.jp> holds the copyright of Config class.

require "cgi" unless Object.const_defined?(:Rack)
require "uri"
require "erb"
require "hiki/util"

module Hiki
  class PluginError < StandardError; end

  class Plugin
    include Hiki::Util
    attr_reader   :toc_f, :plugin_command
    attr_accessor :text, :title, :cookies, :user, :data, :session_id

    TOC_STRING = "\000\000[Table of Contents]"

    def initialize(options, conf)
      @options      = options
      @conf         = conf
      set_tdiary_env

      @cookies = []
      @plugin_method_list = []
      @header_procs     = []
      @update_procs     = []
      @delete_procs     = []
      @body_enter_procs = []
      @body_leave_procs = []
      @page_attribute_procs = []
      @footer_procs     = []
      @edit_procs       = []
      @form_procs       = []
      @menu_procs       = []
      @conf_keys        = []
      @conf_procs       = {}
      @mode             = ""

      options.each do |opt, val|
        instance_variable_set("@#{opt}", val) unless opt.index(".")
      end

      @toc_f            = false
      @context          = nil
      @plugin_command   = []
      @plugin_menu      = []
      @text             = ""

      @mode = "conf" if @request.params["c"] == "admin"
      @mode = "saveconf" if @request.params["saveconf"]

      # loading plugins
      @plugin_files = []
      plugin_path = @conf.plugin_path || "#{PATH}/plugin"
      plugin_file = ""
      begin
        Dir::glob("#{plugin_path}/*.rb").sort.each do |file|
          plugin_file = file
          load_plugin(file)
          @plugin_files << file
        end
      rescue Exception
        raise PluginError, "Plugin error in '#{File::basename(plugin_file)}'.\n#{$!}\n#{$!.backtrace[0]}"
      end
    end

    def block_context?
      @context == :block
    end

    def inline_context?
      @context == :inline
    end

    def block_context(&proc)
      in_context(:block, &proc)
    end

    def inline_context(&proc)
      in_context(:inline, &proc)
    end

    def cookie_path
      path = URI.parse(@conf.base_url).path
      if path[-1] == ?/
        path
      else
        File.dirname(path) + "/"
      end
    end

    def header_proc
      r = []
      @header_procs.each do |proc|
        begin
          r << proc.call
        rescue Exception
          r << plugin_error("header_proc", $!)
        end
      end
      r.join.chomp
    end

    def update_proc
      @update_procs.each do |proc|
        begin
          proc.call
        rescue Exception
        end
      end
    end

    def delete_proc
      @delete_procs.each do |proc|
        begin
          proc.call
        rescue Exception
        end
      end
    end

    def body_enter_proc
      r = []
      @body_enter_procs.each do |proc|
        begin
          r << proc.call(@date)
        rescue Exception
          r << plugin_error("body_enter_proc", $!)
        end
      end
      r.join
    end

    def body_leave_proc
      r = []
      @body_leave_procs.each do |proc|
        begin
          r << proc.call(@date)
        rescue Exception
          r << plugin_error("body_leave_proc", $!)
        end
      end
      r.join
    end

    def page_attribute_proc
      r = []
      @page_attribute_procs.each do |proc|
        begin
          r << proc.call(@date)
        rescue Exception
          r << plugin_error("page_attribute_proc", $!)
        end
      end
      r.join
    end

    def footer_proc
      r = []
      @footer_procs.each do |proc|
        begin
          r << proc.call
        rescue Exception
          r << plugin_error("footer_proc", $!)
        end
      end
      r.join
    end

    def edit_proc
      r = []
      @edit_procs.each do |proc|
        begin
          r << proc.call
        rescue Exception
          r << plugin_error("edit_proc", $!)
        end
      end
      r.join
    end

    def form_proc
      r = []
      @form_procs.each do |proc|
        begin
          r << proc.call
        rescue Exception
          r << plugin_error("form_proc", $!)
        end
      end
      r.join
    end

    def menu_proc
      r = []
      @menu_procs.each do |proc|
        begin
          r << proc.call
        rescue Exception
          r << plugin_error("menu_proc", $!)
        end
      end
      r.compact
    end

    def add_cookie(cookie)
      @cookies << cookie
    end

    def singleton_method_added(name)
      @defined_method_list.push(name)
    end

    def load_file(filename)
      open(filename) do |src|
        instance_eval(src.read.untaint, filename, 1)
      end
    end

    def send(name, *args)
      name = name.intern if name.is_a?(String)
      if not name.is_a?(Symbol)
        raise ArgumentError, "#{name.inspect} is not a symbol"
      end
      if not @plugin_method_list.include?(name)
        method_missing(name, *args)
      else
        __send__(name, *args)
      end
    end

    def each_conf_key
      @conf_keys.each do |key|
        yield key
      end
    end

    def conf_proc(key)
      r = ""
      label, block = @conf_procs[key]
      r = block.call if block
      r
    end

    def conf_label(key)
      label, block = @conf_procs[key]
      label
    end

    def load_plugin(file)
      file.untaint
      @defined_method_list = []
      @export_method_list = nil
      @resource_loaded = false
      dirname, basename = File.split(file)
      [@conf.lang, "en", "ja"].uniq.each do |lang|
        begin
          load_file(File.join(dirname, lang, basename))
          @resource_loaded = true
          break
        rescue IOError, Errno::ENOENT
        end
      end
      load_file(file)
      if @export_method_list
        @plugin_method_list.concat(@export_method_list)
      else
        @plugin_method_list.concat(@defined_method_list)
      end
    end

    def load(page)
      @db.load(page)
    end

    def load_backup(page)
      @db.load_backup(page)
    end

    def save(page, src, md5, update_timestamp = true, filtering = true)
      return false if filtering and Filter.new_page_is_spam?(page, src)

      src.gsub!(/\r/, "")
      src.sub!(/\A\n*/, "")
      src.sub!(/\n*\z/, "\n")
      result = @db.store(page, src, md5, update_timestamp)
      if result
        @db.set_attribute(page, editor: @user)
        @db.delete_cache(page)
        begin
          update_proc
        rescue Exception
        end
      end
      result
    end

    def admin?
      (@user == @conf.admin_name) || @conf.password.empty?
    end

    def login(name, password)
      return if @user
      return nil unless password
      name ||= @conf.admin_name
      if @conf.password.empty? || password.crypt(@conf.password) == @conf.password && name == @conf.admin_name
        @user = @conf.admin_name
      elsif @conf["user.list"]
        if @conf["user.list"].has_key?(name) && @conf["user.list"][name] == password.crypt(@conf["user.list"][name])
          @user = name
        end
      end
    end

    private

    def in_context(context)
      begin
        @context = context
        yield
      ensure
        @context = nil
      end
    end

    def export_plugin_methods(*names)
      @export_method_list = names.collect do |name|
        name = name.intern if name.is_a?(String)
        if not name.is_a?(Symbol)
          raise TypeError, "#{name.inspect} is not a symbol"
        end
        name
      end
    end

    def add_header_proc(block = Proc.new)
      @header_procs << block
    end

    def add_footer_proc(block = Proc.new)
      @footer_procs << block
    end

    def add_update_proc(block = Proc.new)
      @update_procs << block
    end

    def add_delete_proc(block = Proc.new)
      @delete_procs << block
    end

    def add_body_enter_proc(block = Proc.new)
      @body_enter_procs << block
    end

    def add_page_attribute_proc(block = Proc.new)
      @page_attribute_procs << block
    end

    def add_body_leave_proc(block = Proc.new)
      @body_leave_procs << block
    end

    def add_edit_proc(block = Proc.new)
      @edit_procs << block
    end

    def add_form_proc(block = Proc.new)
      @form_procs << block
    end

    def add_menu_proc(block = Proc.new)
      @menu_procs << block
    end

    def add_plugin_command(command, display_text, option = {})
      @plugin_command << command
      @plugin_menu    << {command: command,
                          display_text: display_text,
                          option: option} if display_text
      nil
    end

    def add_conf_proc(key, label, block = Proc.new)
      return unless @mode =~ /^(conf|saveconf)$/
      @conf_keys << key unless @conf_keys.index(key)
      @conf_procs[key] = [label, block]
    end

    def set_tdiary_env
      @date             = Time.now
      @cookies          = []

      @options["cache_path"]  = @conf.cache_path
      @options["mode"]        = "day"
#      @options['author_name'] = @conf.author_name || 'anonymous'
#      @options['author_mail'] = @conf.mail
#      @options['index_page']  = @conf.index_page
#      @options['html_title']  = @conf.site_name
      @options["years"]       = {}
      @options["diaries"]     = nil,
      @options["date"]        = Time.now

      %w(cache_path mode years diaries date).each do |p|
        instance_variable_set("@#{p}", @options[p])
      end
    end
  end
end
