require 'docdiff/diff/rcsdiff'
require 'docdiff/diff/unidiff'

class Diff
  class EditScript
    def initialize
      @chunk_common = nil
      @chunk_add = []
      @chunk_del = []
      @list = []
      @list << @chunk_del
      @list << @chunk_add

      @cs = Subsequence.new
      @count_a = 0
      @count_b = 0
      @additions = 0
      @deletions = 0
    end

    attr_reader :count_a, :additions
    attr_reader :count_b, :deletions

    def commonsubsequence
      return @cs
    end

    def del(seq_or_len)
      unless @chunk_del
        @chunk_add = []
        @chunk_del = []
        @chunk_common = nil
        @list << @chunk_del
        @list << @chunk_add
      end
      if Array === seq_or_len
        len = seq_or_len.length
        mark = :del_elt
      else
        len = seq_or_len
        mark = :del_num
      end
      if !@chunk_del.empty? && @chunk_del.last[0] == mark
        @chunk_del.last[1] += seq_or_len
      else
        @chunk_del << [mark, seq_or_len, nil]
      end
      @count_a += len
      @deletions += len
    end

    def add(seq_or_len)
      unless @chunk_add
        @chunk_add = []
        @chunk_del = []
        @chunk_common = nil
        @list << @chunk_del
        @list << @chunk_add
      end
      if Array === seq_or_len
        len = seq_or_len.length
        mark = :add_elt
      else
        len = seq_or_len
        mark = :add_num
      end
      if !@chunk_add.empty? && @chunk_add.last[0] == mark
        @chunk_add.last[2] += seq_or_len
      else
        @chunk_add << [mark, nil, seq_or_len]
      end
      @count_b += len
      @additions += len
    end

    def common(seq_or_len_a, seq_or_len_b=seq_or_len_a)
      unless @chunk_common
        @list.pop
        @list.pop
        @list << @chunk_del unless @chunk_del.empty?
        @list << @chunk_add unless @chunk_add.empty?
        @chunk_add = nil
        @chunk_del = nil
        @chunk_common = []
        @list << @chunk_common
      end

      len_a = Array === seq_or_len_a ? seq_or_len_a.length : seq_or_len_a
      len_b = Array === seq_or_len_b ? seq_or_len_b.length : seq_or_len_b
      raise ArgumentError.new("length not equal: #{len_a} != #{len_b}") if len_a != len_b
      len = len_a

      mark = ((Array === seq_or_len_a) ?
              (Array === seq_or_len_b ? :common_elt_elt : :common_elt_num) :
              (Array === seq_or_len_b ? :common_num_elt : :common_num_num))

      if !@chunk_common.empty? && @chunk_common.last[0] == mark
        @chunk_common.last[1] += seq_or_len_a
        @chunk_common.last[2] += seq_or_len_b
      else
        @chunk_common << [mark, seq_or_len_a, seq_or_len_b]
      end

      @cs.add @count_a, @count_b, len
      @count_a += len
      @count_b += len
    end

    def each
      @list.each {|chunk|
        chunk.each {|mark_del_add|
          yield mark_del_add
        }
      }
    end

    def apply(src)
      l = 0
      dst = []
      each {|mark, del, add|
        case mark
        when :add_elt
          dst.concat add
        when :add_num
          raise ArgumentError.new("additionnal lines are not known.")
        when :common_elt_elt
          dst.concat add
          l += del.length
        when :common_elt_num
          dst.concat src[l, del]
          l += del
        when :common_num_elt
          dst.concat add
          l += add
        when :common_num_num
          dst.concat src[l, del]
          l += del
        when :del_elt
          l += del.length
        when :del_num
          l += del
        end
      }
      dst.concat src[l..-1]
      return dst
    end
  end
end
