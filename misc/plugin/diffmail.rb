# $Id: diffmail.rb,v 1.6 2005-01-28 04:35:30 fdiary Exp $
# Copyright (C) 2004-2005 Kazuhiko <kazuhiko@fdiary.net>

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
      src = @db.text
      dst = latest_text
      r = unified_diff( src, dst, unified )
    end
    send_updating_mail(@page, type, head + r) unless (head + r).empty?
  rescue
  end
end
