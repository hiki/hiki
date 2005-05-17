class Diff
  def Diff.rcsdiff(a, b)
    al = []
    a.each_line {|l| al << l}
    bl = []
    b.each_line {|l| bl << l}
    return Diff.new(al, bl).ses.rcsdiff
  end

  class EditScript
    def EditScript.parse_rcsdiff(input)
      ses = EditScript.new
      l = 1
      scan_rcsdiff(input) {|mark, beg, len, lines|
        if mark == :del
          ses.common beg - l if l < beg
          ses.del len
          l = beg + len
        else
          ses.add lines
        end
      }
      return ses
    end

    def EditScript.scan_rcsdiff(input)
      state = :command
      beg = len = nil
      adds = nil
      input.each_line("\n") {|line|
        case state
        when :command
          case line
          when /\Aa(\d+)\s+(\d+)/
            beg = $1.to_i
            len = $2.to_i
            adds = []
            state = :add
          when /\Ad(\d+)\s+(\d+)/
            beg = $1.to_i
            len = $2.to_i
            yield :del, beg, len, nil
            state = :command
          else
            raise InvalidRCSDiffFormat.new(line)
          end
        when :add
          adds << line
          if adds.length == len
            yield :add, beg, len, adds
            adds = nil
            state = :command
          end
        else
          raise StandardError.new("unknown state")
        end
      }
    end

    def rcsdiff(out='')
      state = :lines
      l = 1
      each {|mark, del, add|
        case mark
        when :add_elt
          out << "a#{l - 1} #{add.length}\n"
          add.each {|line|
            case state
            when :lines
              case line
              when /\A.*\n\z/
              when /\A.*\z/
                state = :after_last_line
              else
                raise ArgumentError.new("additional element is not line")
              end
            when :after_last_line
              raise ArgumentError.new("additional elements after last incomplete line")
            end
            out << line
          }
        when :add_num
          raise ArgumentError.new("additionnal lines are not known.")
        when :common_elt_elt
          l += del.length
        when :common_elt_num
          l += add
        when :common_num_elt
          l += del
        when :common_num_num
          l += del
        when :del_elt
          del = del.length
          out << "d#{l} #{del}\n"
          l += del
        when :del_num
          out << "d#{l} #{del}\n"
          l += del
        end
      }
      return out
    end

    class InvalidRCSDiffFormat < StandardError
    end
  end
end
