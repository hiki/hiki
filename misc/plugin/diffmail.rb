# $Id: diffmail.rb,v 1.4 2005-01-04 14:11:51 fdiary Exp $
# Copyright (C) 2003 SHIMADA Mitsunobu <simm@fan.jp>

#----- send a mail on updating
def updating_mail
  begin
    latest_text = @db.load(@page) || ''
    type = (!@db.text or @db.text.size == 0) ? 'create' : 'update'
    if type == 'create' then
      text = "#{latest_text}\n"
    elsif type == 'update'
      text = ''
      src = @db.text
      dst = latest_text
      r = diff( src, dst, unified )
    end
    send_updating_mail(@page, type, text)
  rescue
  end
end
