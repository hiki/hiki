=begin
Diff::ShortestPath uses the algorithm described in following paper.

[Wu1990] Sun Wu, Udi Manber, Gene Myers and Webb Miller,
An O(NP) Sequence Comparison Algorithm,
Information Processing Letters 35, 1990, 317-323
=end

class Diff
  class ShortestPath
    def initialize(a, b)
      if a.length > b.length
        @a = b
        @b = a
        @exchanged = true
      else
        @a = a
        @b = b
        @exchanged = false
      end
      @m = @a.length
      @n = @b.length
    end

    def lcs(lcs=Subsequence.new)
      d = @n - @m
      fp = Array.new(@n+1+@m+1+1, -1)
      fp_base = -(@m+1)
      path = Array.new(fp.length)
      p = -1
      begin
        p += 1
        (-p).upto(d-1) {|k|
          a = fp[fp_base+k-1]+1
          b = fp[fp_base+k+1]
          if a < b
            y = fp[fp_base+k] = snake(k, b)
            path[fp_base+k] = path[fp_base+k+1]
            path[fp_base+k] = [y - k, y, y - b, path[fp_base+k]] if b < y
          else
            y = fp[fp_base+k] = snake(k, a)
            path[fp_base+k] = path[fp_base+k-1]
            path[fp_base+k] = [y - k, y, y - a, path[fp_base+k]] if a < y
          end
        }
        (d+p).downto(d+1) {|k|
          a = fp[fp_base+k-1]+1
          b = fp[fp_base+k+1]
          if a < b
            y = fp[fp_base+k] = snake(k, b)
            path[fp_base+k] = path[fp_base+k+1]
            path[fp_base+k] = [y - k, y, y - b, path[fp_base+k]] if b < y
          else
            y = fp[fp_base+k] = snake(k, a)
            path[fp_base+k] = path[fp_base+k-1]
            path[fp_base+k] = [y - k, y, y - a, path[fp_base+k]] if a < y
          end
        }
        a = fp[fp_base+d-1]+1
        b = fp[fp_base+d+1]
        if a < b
          y = fp[fp_base+d] = snake(d, b)
          path[fp_base+d] = path[fp_base+d+1]
          path[fp_base+d] = [y - d, y, y - b, path[fp_base+d]] if b < y
        else
          y = fp[fp_base+d] = snake(d, a)
          path[fp_base+d] = path[fp_base+d-1]
          path[fp_base+d] = [y - d, y, y - a, path[fp_base+d]] if a < y
        end
      end until fp[fp_base+d] == @n
      shortest_path = path[fp_base+d]
      list = []
      while shortest_path
        x, y, l, shortest_path = shortest_path
        list << [x - l, y - l, l]
      end
      if @exchanged
        list.collect {|xyl| tmp = xyl[0]; xyl[0] = xyl[1]; xyl[1] = tmp}
      end
      list.reverse_each {|xyl| lcs.add(*xyl)}
      return lcs
    end

    def snake(k, y)
      x = y - k
      while x < @m && y < @n && @a[x] == @b[y]
        x += 1
        y += 1
      end
      return y
    end
  end
end
