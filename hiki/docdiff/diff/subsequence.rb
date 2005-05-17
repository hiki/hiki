class Diff
  class Subsequence
    def initialize
      @list = []
    end

    def add(i, j, len=1)
      raise ArgumentError.new("non-positive length: #{len}") if len <= 0

      if @list.empty?
        @list << [i, j, len]
        return
      end

      i0, j0, len0 = @list.last

      if i0 + len0 == i && j0 + len0 == j
        @list.last[2] += len
        return
      end

      if i0 + len0 > i || j0 + len0 > j
        raise ArgumentError.new("additional common sequence overlapped.")
      end

      @list << [i, j, len]
    end

    def each(&block)
      @list.each(&block)
    end

    def length
      len = 0
      each {|i, j, l| len += l}
      return len
    end
  end
end
