
require "rubygems"
require "rack"

require "hiki/config"
require "hiki/util"

$LOAD_PATH.unshift(File.dirname(__FILE__))

module Hiki
  class Attachment
    include ::Hiki::Util
    def initialize(config_path)
      @config_path = config_path
    end

    def call(env)
      request = Hiki::Request.new(env)
      # HACK replace ENV values to web application environment
      env.each{|k,v| ENV[k] = v.to_s unless /\Arack\./ =~ k }
      conf = Hiki::Config.new(@config_path)
      response = attach_file(request, conf)
      response.finish
    end

    private

    def attach_file(request, conf)
      unless /^attach\.rb$/ =~ conf.options["sp.selected"]
        return Hiki::Response.new('plugin "attach.rb" is not enabled',
                                  404, "type" => "text/plain")
      end
      set_conf(conf)
      params = request.params
      page = params["p"] ? params["p"] : "FrontPage"
      command = params["command"] ? params["command"] : "view"
      command = "view" unless ["view", "edit"].include?(command)
      case
      when params["attach"]
        attach(request, page, command)
      when params["detach"]
        detach(request, page, command)
      else
        raise 'must specify parameter "attach"/"detach".'
      end
      redirect(request, "#{@conf.index_url}?c=#{command}&p=#{escape(page)}")
    rescue Exception => ex
      Hiki::Response.new(ex.message, 500, "type" => "text/plain")
    end

    def attach(request, page, command)
      params = request.params
      raise "Invalid request." unless params["p"] && params["attach_file"]
      attach_file = params["attach_file"]
      filename = File.basename(attach_file[:filename].gsub(/\\/, "/"))
      cache_path = "#{@conf.cache_path}/attach"
      attach_path = "#{cache_path}/#{escape(page)}"
      Dir.mkdir(cache_path) unless test(?e, cache_path.untaint)
      Dir.mkdir(attach_path) unless test(?e, attach_path.untaint)
      path = "#{attach_path}/#{escape(filename)}"
      max_size = @conf.options["attach_size"] || 1048576 # 1 MB
      if attach_file[:tempfile].size > max_size
        raise "File size is larger than limit (#{max_size} bytes)."
      end
      unless filename.empty?
        content = attach_file[:tempfile].read
        if (!@conf.options["attach.allow_script"]) && (/<script\b/i =~ content)
          raise "You cannot attach a file that contains scripts."
        else
          File.open(path.untaint, "wb") do |file|
            file.print content
          end
          result = ""
          result << "FILE        = #{File.basename(path)}\n"
          result << "SIZE        = #{File.size(path)} bytes\n"
          send_updating_mail(page, "attach", result) if @conf.mail_on_update
        end
      end
    end

    def detach(request, page, command)
      params = request.params
      p params
      attach_path = "#{@conf.cache_path}/attach/#{escape(page)}"
      result = ""
      Dir.foreach(attach_path) do |file|
        next unless params["file_#{file}"]
        path = "#{attach_path}/#{file}"
        if FileTest.file?(path.untaint) && params["file_#{file}"]
          File.unlink(path)
          result << "FILE        = #{File.basename(path)}\n"
        end
      end
      Dir.rmdir(attach_path) if Dir.entries(attach_path).size == 2
      send_updating_mail(page, "detach", result) if @conf.mail_on_update
    end
  end
end
