module Hiki
  class Registry

    attr_reader :kind

    def initialize(kind, search_prefix = nil)
      @kind = kind
      @search_prefix = search_prefix
      @map = {}
    end

    def []=(type, value)
      @map[type.to_sym] = value
    end

    def [](type)
      type = type.to_sym
      return @map[type] if @map.key?(type)
      raise Error.new(@kind, type)
    end

    class Error < StandardError
      def initialize(kind, type)
        @kind = kind
        @type = type
        super "Unknown #{@kind} '#{@type}'"
      end
    end
  end
end
