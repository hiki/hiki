# $Id: diffmail2.rb,v 1.2 2004-09-10 06:37:42 fdiary Exp $
# Copyright (C) 2003 SHIMADA Mitsunobu <simm@fan.jp>

require 'hiki/algorithm/diff'

#----- send a mail on updating
def updating_mail
  begin
    latest_text = @db.load(@page) || ''
    title = @params['page_title'][0] ? @params['page_title'][0].strip : @page
    keyword = (@params['keyword'][0]||'').split("\n").collect {|k|
      k.chomp.strip}.delete_if{|k| k.empty?}.join(' / ')
    head = ''
    type = (!@db.text or @db.text.empty?) ? 'create' : 'update'
    if type == 'create' then
      head << "TITLE       = #{title}\n"
      head << "KEYWORD     = #{keyword}\n"
      r = "#{latest_text}\n"
    elsif type == 'update'
      title_old = page_name(@page)
      keyword_old = @db.get_attribute(@page, :keyword).join(' / ')
      unless title == title_old
	head << "TITLE       = #{title_old} -> #{title}\n"
      end
      unless keyword == keyword_old
	head << "KEYWORD     = #{keyword_old} -> #{keyword}\n"
      end
      head << "-------------------------\n" unless head.empty?

      unified = @options['diffmail.lines'] || 3
      r = ''
      src = @db.text.split("\n").collect{|s| "#{s}\n"}
      dst = latest_text.split("\n").collect{|s| "#{s}\n"}
      si = 0
      di = 0
      sibak = nil
      dibak = nil
      Diff.diff( src, dst ).each do |action, position, elements|

        # difference
        case action
        when :-
          # postfix
          if unified and sibak then
            while( (si < sibak + unified) and (si < position) )
              r << "  #{src[si]}"
              si += 1
              di += 1
            end
            r << "---\n" if si < position - 1
          end
          # prefix
          while si < position
            if( (not unified) or (position - unified <= si) )
              r << "  #{src[si]}"
            end
            si += 1
            di += 1
          end
          si += elements.length
          elements.each do |l|
            r << "- #{l}"
          end
        when :+
          # postfix
          if unified and dibak then
            while( (di < dibak + unified) and (di < position) )
              r << "  #{dst[di]}"
              si += 1
              di += 1
            end
            r << "---\n" if di < position - 1
          end
          # prefix
          while di < position
            if( (not unified) or (position - unified <= di) )
              r << "  #{dst[di]}"
            end
            si += 1
            di += 1
          end
          di += elements.length
          elements.each do |l|
            r << "+ #{l}"
          end
        end

        # record for the next
        sibak = si
        dibak = di
      end

      # postfix
      if unified and sibak then
        while( (si < sibak + unified) and (si < src.length) )
          r << "  #{src[si]}"
          si += 1
          di += 1
        end
      elsif !r.empty?
        while si < src.length
          r << "  #{src[si]}"
          si += 1
        end
      end
      r
    end
    send_updating_mail(@page, type, head + r) unless (head + r).empty?
  rescue
  end
end
