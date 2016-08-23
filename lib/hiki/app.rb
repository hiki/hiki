
require "rubygems"
require "rack"

require "hiki/config"
require "hiki/repository"
require "hiki/xmlrpc"

$LOAD_PATH.unshift(File.dirname(__FILE__))

module Hiki
  class App
    def initialize(config_path = "hikiconf.rb")
      @config_path = config_path
    end
    def call(env)
      request = Rack::Request.new(env)
      # TODO use Rack::Request#env or other methods instead of ENV
      # HACK replace ENV values to web application environment
      env.each{|k,v| ENV[k] = v.to_s unless /\Arack\./ =~ k }
      conf = Hiki::Config.new(@config_path)
      response = nil
      if %r|text/xml| =~ request.content_type and request.post?
        server = Hiki::XMLRPCServer.new(conf, request)
        response = server.serve
      else
        db = conf.database
        db.open_db do
          command = Hiki::Command.new(request, db, conf)
          response = command.dispatch
        end
      end

      response.header.delete("status")
      response.header.delete("cookie")

      charset = response.header.delete("charset")
      response.header["Content-Type"] ||= response.header.delete("type")
      response.header["Content-Type"] += "; charset=#{charset}" if charset

      response.body = [] if request.head?

      response.finish
    end
  end
end
