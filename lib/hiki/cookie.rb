

module Hiki
  if Object.const_defined?(:Rack)
    class Cookie
      attr_reader :name, :value, :path, :expires
      def initialize(options)
        @name    = options["name"]
        @value   = options["value"]
        @path    = options["path"]
        @expires = options["expires"]
      end
    end
  else
    Cookie = ::CGI::Cookie
  end
end
