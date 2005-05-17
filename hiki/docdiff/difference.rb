# Difference class for DocDiff
# 2003-03-24 .. 
# Hisashi MORITA

require 'docdiff/diff'

class Difference < Array

#  @resolution = nil # char, word, phrase, sentence, line, paragraph..
#  @codeset = ''
#  @eol_char = "\n"
#  @source = 'source'
#  @target = 'target'
#  attr_accessor :resolution, :codeset, :eol_char, :source, :target

  def initialize(array1 = nil, array2 = nil)
    if (array1 == nil) && (array2 == nil)
      return []
    end
    diff = Diff.new(array1, array2)
    @raw_list = []
    diff.ses.each{|block|  # Diff::EditScript does not have each_with_index()
      @raw_list << block
    }
    combine_del_add_to_change!()
  end

  def combine_del_add_to_change!()

    @raw_list.each_with_index{|block, i|
      case block.first
      when :common_elt_elt
        if i == 0                       # first block
          self << block
        else                            # in-between or the last block
          if @raw_list[i - 1].first == :del_elt  # previous block was del
            self << @raw_list[i - 1]
            self << block
          else                                   # previous block was add
            self << block
          end
        end
      when :del_elt
        if i == (@raw_list.size - 1)    # last block
          self << block
        else                            # first block or in-between
          # do nothing, let the next block to decide what to do
        end
      when :add_elt
        if i == 0                       # first block
          self << block
        else                            # in-between or the last block
          if @raw_list[i - 1].first == :del_elt  # previous block was del
            deleted = @raw_list[i - 1][1]
            added   = @raw_list[i][2]
            self << [:change_elt, deleted, added]
          else                                   # previous block was common
            self << block
          end
        end
      else
        raise "the first element of the block #{i} is invalid: (#{block.first})\n"
      end
    }
  end
  attr_accessor :raw_list

end  # class Difference
