=begin
= Diff
--- Diff.new(seq_a, seq_b)
--- Diff#ses([algorithm=:speculative])
--- Diff#lcs([algorithm=:speculative])

    Available algorithms are follows.
    * :shortestpath
    * :contours
    * :speculative

= Diff::EditScript
--- Diff::EditScript.new
--- Diff::EditScript#del(seq_or_len_a)
--- Diff::EditScript#add(seq_or_len_b)
--- Diff::EditScript#common(seq_or_len_a[, seq_or_len_b])
--- Diff::EditScript#commonsubsequence
--- Diff::EditScript#count_a
--- Diff::EditScript#count_b
--- Diff::EditScript#additions
--- Diff::EditScript#deletions
--- Diff::EditScript#each {|mark, a, b| ...}
--- Diff::EditScript#apply(arr)
--- Diff::EditScript.parse_rcsdiff(input)
--- Diff::EditScript#rcsdiff([out=''])

= Diff::Subsequence
--- Diff::Subsequence.new
--- Diff::Subsequence.add(i, j[, len=1])
--- Diff::Subsequence#length
--- Diff::Subsequence#each {|i, j, len| ...}
=end

require 'docdiff/diff/editscript'
require 'docdiff/diff/subsequence'
require 'docdiff/diff/shortestpath'
require 'docdiff/diff/contours'
require 'docdiff/diff/speculative'

=begin
Data class reduces input for diff and convert alphabet to Integer.

It reduces input by removing common prefix, suffix and
unique elements.

So, reduced input has following properties:
* First element is different.
* Last element is different.
* Any elemnt in A is also exist in B.
* Any elemnt in B is also exist in A.

=end
class Diff
  def initialize(a, b)
    @original_a = a
    @original_b = b

    count_a = {}
    count_a.default = 0
    a.each {|e| count_a[e] += 1}

    count_b = {}
    count_b.default = 0
    b.each {|e| count_b[e] += 1}

    beg_a = 0
    end_a = a.length

    beg_b = 0
    end_b = b.length

    @prefix_lcs = []
    @suffix_lcs = []

    flag = true
    while flag
      flag = false

      while beg_a < end_a && beg_b < end_b && a[beg_a].eql?(b[beg_b])
        @prefix_lcs << [beg_a, beg_b]
        count_a[a[beg_a]] -= 1
        count_b[b[beg_b]] -= 1
        beg_a += 1
        beg_b += 1
        flag = true
      end

      while beg_a < end_a && beg_b < end_b && a[end_a - 1].eql?(b[end_b - 1])
        @suffix_lcs << [end_a - 1, end_b - 1]
        count_a[a[end_a - 1]] -= 1
        count_b[b[end_b - 1]] -= 1
        end_a -= 1
        end_b -= 1
        flag = true
      end

      while beg_a < end_a && count_b[a[beg_a]] == 0
        count_a[a[beg_a]] -= 1
        beg_a += 1
        flag = true
      end

      while beg_b < end_b && count_a[b[beg_b]] == 0
        count_b[b[beg_b]] -= 1
        beg_b += 1
        flag = true
      end

      while beg_a < end_a && count_b[a[end_a - 1]] == 0
        count_a[a[end_a - 1]] -= 1
        end_a -= 1
        flag = true
      end

      while beg_b < end_b && count_a[b[end_b - 1]] == 0
        count_b[b[end_b - 1]] -= 1
        end_b -= 1
        flag = true
      end
    end

    @alphabet = Alphabet.new

    @a = []
    @revert_index_a = []
    (beg_a...end_a).each {|i|
      if count_b[a[i]] != 0
        @a << @alphabet.add(a[i])
        @revert_index_a << i
      end
    }

    @b = []
    @revert_index_b = []
    (beg_b...end_b).each {|i|
      if count_a[b[i]] != 0
        @b << @alphabet.add(b[i])
        @revert_index_b << i
      end
    }
  end

  def Diff.algorithm(algorithm)
    case algorithm
    when :shortestpath
      return ShortestPath
    when :contours
      return Contours
    when :speculative
      return Speculative
    else
      raise ArgumentError.new("unknown diff algorithm: #{algorithm}")
    end
  end

  def lcs(algorithm=:speculative) # longest common subsequence
    klass = Diff.algorithm(algorithm)
    reduced_lcs = klass.new(@a, @b).lcs

    lcs = Subsequence.new
    @prefix_lcs.each {|i, j| lcs.add i, j}
    reduced_lcs.each {|i, j, l|
      l.times {|k|
        lcs.add @revert_index_a[i+k], @revert_index_b[j+k]
      }
    }
    @suffix_lcs.reverse_each {|i, j| lcs.add i, j}

    return lcs
  end

  def ses(algorithm=nil) # shortest edit script
    algorithm ||= :speculative
    lcs = lcs(algorithm)
    ses = EditScript.new
    i0 = j0 = 0
    lcs.each {|i, j, l|
      ses.del @original_a[i0, i - i0] if i0 < i
      ses.add @original_b[j0, j - j0] if j0 < j
      ses.common @original_a[i, l], @original_b[j, l]

      i0 = i + l
      j0 = j + l
    }

    i = @original_a.length
    j = @original_b.length
    ses.del @original_a[i0, i - i0] if i0 < i
    ses.add @original_b[j0, j - j0] if j0 < j

    return ses
  end

  class Alphabet
    def initialize
      @hash = {}
    end

    def add(v)
      if @hash.include? v
        return @hash[v]
      else
        return @hash[v] = @hash.size
      end
    end

    class NoSymbol < StandardError
    end
    def index(v)
      return @hash.fetch {raise NoSymbol.new(v.to_s)}
    end

    def size
      return @hash.size
    end
  end
end
