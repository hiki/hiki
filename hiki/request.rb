# -*- coding: utf-8 -*-

module Hiki
  if Module.const_defined?(:CGI)
    # CGI を Rack::Request っぽいインターフェイスに変換する
    class Request
      attr_reader :env
      def initialize(env)
        @cgi = CGI.new
        @env = env
      end

      def params
        return @params if @params
        @params = { }
        @cgi.params.map{|k,v| @params[k] = v[0] }
        @params
      end

      def [](key)
        params[key]
      end

      def []=(key, val)
        params[key] = val
      end

      def accept_encoding
      end

      def body
      end

      def content_charset
        @env['CONTENT_CHARSET']
      end

      def content_length
        @env['CONTENT_LENGTH']
      end

      def content_type
        @env['CONTENT_TYPE']
      end

      def cookies
      end

      def delete?
      end

      def form_data?
      end

      def fullpath
      end

      def get?
      end

      def head?
      end

      def host
      end

      def ip
      end

      def media_type
      end

      def media_type_params
      end

      def openid_request
        raise 'not implemented'
      end

      def openid_response
        raise 'not implemented'
      end

      def parseable_data?
      end

      def path
      end

      def path_info
      end

      def path_info=(s)
      end

      def port
      end

      def post?
      end

      def put?
      end

      def query_string
      end

      def referer
      end
      alias referrer referer

      def request_method
        @env['REQUEST_METHOD']
      end

      def schema
      end

      def script_name
      end

      def session_options
      end

      def url
      end

      def values_at(*keys)
      end

      def xhr?
      end
    end
  else
    Request = Rack::Request
  end
end
