
require 'rubygems'
require 'rack'

require 'hiki/config'
require 'hiki/xmlrpc'

module Hiki
  class App
    def call(env)
      request = Rack::Request.new(env)
      # TODO use Rack::Request#env or other methods instead of ENV
      # HACK replace ENV values to web application environment
      env.each{|k,v| ENV[k] = v unless /\Arack\./ =~ k }
      conf = Hiki::Config.new
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
      # [body, status, headers]
      # Rack::Response.new(*response){|r|
      # }.finish
      response.header.delete('status')
      response.finish
    end
  end
end
