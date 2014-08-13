# -*- coding: utf-8 -*-

require 'hiki/farm/config'
require 'hiki/farm/wiki'
require 'hiki/farm/manager'
require 'hiki/farm/dispatcher'
require 'hiki/farm/page'

module Hiki
  module Farm
    VERSION = '2.0.0.pre1'
    RELEASE_DATE = '2014-08-13'
  end
end

# for backward compatibility
HIKIFARM_VERSION = Hiki::Farm::VERSION
HIKIFARM_RELEASE_DATE = Hiki::Farm::RELEASE_DATE

module Hiki
  module Farm
    class App

      def initialize(conf)
        @conf = conf
      end

      def call(env)
        manager = ::Hiki::Farm::Manager.new(@conf)
        request = Rack::Request.new(env)
        # rss, index, error?
        response = run(manager, request)
        response.finish
      end

      private

      def run(manager, request)
        case
        when request.get? && %r!\A/#{::Hiki::Farm::RSSPage.page_name}\z! =~ request.path_info
          body = ::Hiki::Farm::RSSPage.new(@conf, manager, File.dirname(request.url)).to_s
          ::Hiki::Response.new(body, 200, { })
        when request.get? && 'rss' == request.params[manager.command_key]
          body = ::Hiki::Farm::RSSPage.new(@conf, manager, File.dirname(request.url)).to_s
          ::Hiki::Response.new(body, 200, { })
        when request.post? && request.params['wiki'] && !request.params['wiki'].empty?
          begin
            name = request.params['wiki']
            raise 'invalid wiki name' unless /\A[a-zA-Z0-9]+\z/ =~ name
            manager.create_wiki(name)
            ::Hiki::Response.new('post', 302, { 'Location' => request.url })
          rescue
            puts $!.message
            puts $!.backtrace.join("\n")
            body = ::Hiki::Farm::IndexPage.new(@conf, manager, request.url, $!.message).to_s
            ::Hiki::Response.new(body, 200, { })
          end
        else
          body = ::Hiki::Farm::IndexPage.new(@conf, manager, request.url, '').to_s
          ::Hiki::Response.new(body, 200, { })
        end
      end
    end
  end
end
