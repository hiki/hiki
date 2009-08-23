

module Hiki
  if Object.const_defined?(:CGI)
    Cookie = ::CGI::Cookie
  else
    class Cookie
      attr_reader :name, :value
      def initialize(options)
        @name    = options['name']
        @value   = options['value']
        @path    = options['path']
        @expires = options['expires']
      end
    end
  end
end
