# $Id: diffmail.rb,v 1.3 2004-09-06 15:08:44 fdiary Exp $
# Copyright (C) 2003 SHIMADA Mitsunobu <simm@fan.jp>

require 'hiki/algorithm/diff'

#----- send a mail on updating
def updating_mail
  begin
    latest_text = @db.load(@page) || ''
    type = (!@db.text or @db.text.size == 0) ? 'create' : 'update'
    if type == 'create' then
      text = "#{latest_text}\n"
    elsif type == 'update'
      text = ''
      src = @db.text.split("\n").collect{|s| "#{s}\n"}
      dst = latest_text.split("\n").collect{|s| "#{s}\n"}
      si = 0
      di = 0
      Diff.diff(src,dst).each do |action,position,elements|
        case action
        when :-
          while si < position
            text << "  #{src[si]}"
            si += 1
            di += 1
          end
          si += elements.length
          elements.each do |l|
            text << "- #{l}"
          end
        when :+
          while di < position
            text << "  #{src[si]}"
            si += 1
            di += 1
          end
          di += elements.length
          elements.each do |l|
            text << "+ #{l}"
          end
        end
      end
      while si < src.length
        text << "  #{src[si]}"
        si += 1
      end
    end
    send_updating_mail(@page, type, text)
  rescue
  end
end
