

module Hiki
  if Object.const_defined?(:CGI)
    class Response
      attr_reader :body, :status, :headers
      def initialize(body = [], status = 200, headers = {}, &block)
        @cgi = CGI.new
        @body = body
        @status = status
        @headers = headers
        yield self if block_given?
      end

      def header
        @cgi.header(@headers)
      end
    end
  else
    Response = ::Rack::Response
  end
end
