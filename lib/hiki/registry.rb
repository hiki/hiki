module Hiki
  class Registry

    attr_reader :kind

    def initialize(kind)
      @kind = kind
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

    module ClassMethods
      def register(name, klass)
        self::REGISTRY[name] = klass
      end

      def lookup(name)
        self::REGISTRY[name]
      end
    end
  end
end
