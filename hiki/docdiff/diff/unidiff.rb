class Diff
  def Diff.unidiff(a, b, algorithm=nil)
    al = []
    a.each_line {|l| al << l}
    bl = []
    b.each_line {|l| bl << l}
    return Diff.new(al, bl).ses(algorithm).unidiff
  end

  class EditScript
    def unidiff_hunk_header(l1, ll1, l2, ll2)
      l1 = 0 if ll1 == 0
      l2 = 0 if ll2 == 0
      result = "@@ -#{l1}"
      result << ",#{ll1}" if ll1 != 1
      result << " +#{l2}"
      result << ",#{ll2}" if ll2 != 1
      result << " @@\n"
    end

    def unidiff(out='', context_lines=3)
      state = :common
      l1 = l2 = 1
      hunk = []
      hunk_l1 = hunk_l2 = 1
      hunk_tail = 0
      each {|mark, del, add|
        case mark
        when :add_elt
          unless hunk
            hunk = []
            hunk_l1 = l1
            hunk_l2 = l2
          end

          add.each {|line| hunk << '+' + line}
          hunk[-1] += "\n\\ No newline at end of file\n" if /\n\z/ !~ hunk[-1]
          l2 += add.length
          hunk_tail = 0
        when :add_num
          raise ArgumentError.new("additionnal lines are not known.")
        when :common_elt_elt
          if hunk
            if hunk_tail + add.length <= context_lines * 2
              add.each {|line| hunk << ' ' + line}
              hunk[-1] += "\n\\ No newline at end of file\n" if /\n\z/ !~ hunk[-1]
              l1 += add.length
              l2 += add.length
              hunk_tail += add.length
            else
              i = 0
              if hunk_tail != hunk.length
                while hunk_tail < context_lines
                  hunk << ' ' + add[i]
                  l1 += 1
                  l2 += 1
                  hunk_tail += 1
                  i += 1
                end
                hunk[-1] += "\n\\ No newline at end of file\n" if /\n\z/ !~ hunk[-1]

                out << unidiff_hunk_header(hunk_l1, l1 - hunk_l1, hunk_l2, l2 - hunk_l1)
                h = hunk.length - (hunk_tail - context_lines)
                (0...h).each {|j| out << hunk[j]}
                hunk[0, h] = []
              end

              l1 += add.length - i
              l2 += add.length - i

              hunk_l1 = l1 - context_lines
              hunk_l2 = l2 - context_lines
              hunk = add[-context_lines..-1].collect {|line| ' ' + line}
              hunk[-1] += "\n\\ No newline at end of file\n" if /\n\z/ !~ hunk[-1]
              hunk_tail = context_lines
            end
          else
            hunk_l1 = l1
            hunk_l2 = l2
            l1 += add.length
            l2 += add.length
            if context_lines <= add.length
              hunk = add[-context_lines..-1].collect {|line| ' ' + line}
            else
              hunk = add.collect {|line| ' ' + line}
            end
            hunk[-1] += "\n\\ No newline at end of file\n" if /\n\z/ !~ hunk[-1]
            hunk_tail = hunk.length
          end
        when :common_elt_num
          raise ArgumentError.new("deleted lines are not known.")
        when :common_num_elt
          raise ArgumentError.new("additional lines are not known.")
        when :common_num_num
          raise ArgumentError.new("deleted and additional lines are not known.")
        when :del_elt
          if hunk_tail == hunk.length && context_lines < hunk_tail
            i = hunk_tail - context_lines
            hunk[0, i] = []
            hunk_l1 += i
            hunk_l2 += i
          end
          del.each {|line| hunk << '-' + line}
          hunk[-1] += "\n\\ No newline at end of file\n" if /\n\z/ !~ hunk[-1]
          l1 += del.length
          hunk_tail = 0
        when :del_num
          raise ArgumentError.new("deleted lines are not known.")
        end
      }
      if hunk_tail != hunk.length
        if context_lines < hunk_tail
          i = hunk_tail - context_lines
          hunk[-i..-1] = []
          l1 -= i
          l2 -= i
        end
        out << unidiff_hunk_header(hunk_l1, l1 - hunk_l1, hunk_l2, l2 - hunk_l1)
        hunk.each {|line| out << line}
      end
      return out
    end
  end
end
