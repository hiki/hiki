# -*- coding: utf-8 -*-

module Hiki
  if Object.const_defined?(:CGI)
    # CGI を Rack::Request っぽいインターフェイスに変換する
    class Request
      attr_reader :env, :cgi
      def initialize(env)
        @cgi = CGI.new
        @env = env
      end

      def params
        return @params if @params
        @params = { }
        @cgi.params.each{|k,v|
          case v.size
          when 0
            @params[k] = nil
          when 1
            @params[k] = v[0]
          else
            @params[k] = v
          end
        }
        @params
      end

      def [](key)
        params[key.to_s]
      end

      def []=(key, val)
        params[key.to_s] = val
      end

      def request_method
        @env['REQUEST_METHOD']
      end

      def header(header)
        @cgi.header(header)
      end

      def get?
        request_method == 'GET'
      end

      def head?
        request_method = 'HEAD'
      end

      def post?
        request_method == 'POST'
      end

      def put?
        request_method == 'PUT'
      end

      def delete?
        request_method == 'DELETE'
      end

      def xhr?
        raise 'not implemented'
      end

      def accept_encoding
        raise 'not implemented'
      end

      def body
        raise 'not implemented'
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

      def remote_addr
        @env['REMOTE_ADDR']
      end

      def cookies
        return @cookies if @cookies
        @cookies = { }
        @cgi.cookies.each{|k, v|
          case v.size
          when 0
            @cookies[k] = nil
          when 1
            @cookies[k] = v[0]
          else
            @cookies[k] = v
          end
        }
        @cookies
      end

      def form_data?
        raise 'not implemented'
      end

      def fullpath
        raise 'not implemented'
      end

      def host
        raise 'not implemented'
      end

      def ip
        raise 'not implemented'
      end

      def media_type
        raise 'not implemented'
      end

      def media_type_params
        raise 'not implemented'
      end

      def openid_request
        raise 'not implemented'
      end

      def openid_response
        raise 'not implemented'
      end

      def parseable_data?
        raise 'not implemented'
      end

      def path
        raise 'not implemented'
      end

      def path_info
        raise 'not implemented'
      end

      def path_info=(s)
        raise 'not implemented'
      end

      def port
        raise 'not implemented'
      end

      def query_string
        raise 'not implemented'
      end

      def referer
        raise 'not implemented'
      end
      alias referrer referer

      def schema
        raise 'not implemented'
      end

      def script_name
        raise 'not implemented'
      end

      def session_options
        raise 'not implemented'
      end

      def url
        raise 'not implemented'
      end

      def values_at(*keys)
        raise 'not implemented'
      end
    end
  else
    Request = ::Rack::Request
    class ::Rack::Request
      alias remote_addr ip
    end
  end
end
