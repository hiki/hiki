# $Id: diffmail.rb,v 1.11 2005-07-17 14:29:06 fdiary Exp $
# Copyright (C) 2004-2005 Kazuhiko <kazuhiko@fdiary.net>

#----- send a mail on updating
def updating_mail
  begin
    latest_text = @db.load(@page) || ''
    if @params['page_title'][0]
      title = @params['page_title'][0].empty? ? @page : @params['page_title'][0].strip
    else
      title = nil
    end
    if @params['keyword'][0]
      keyword = (@params['keyword'][0]||'').split("\n").collect {|k|
        k.chomp.strip}.delete_if{|k| k.empty?}.join(' / ')
    else
      keyword = nil
    end
    head = ''
    type = (!@db.text or @db.text.empty?) ? 'create' : 'update'
    if type == 'create' then
      head << "TITLE       = #{title}\n" if title
      head << "KEYWORD     = #{keyword}\n" if keyword
      r = "#{latest_text}\n"
    elsif type == 'update'
      title_old = CGI::unescapeHTML( page_name( @page ) )
      keyword_old = @db.get_attribute(@page, :keyword).join(' / ')
      if title && title != title_old
        head << "TITLE       = #{title_old} -> #{title}\n"
      end
      if keyword && keyword != keyword_old
        head << "KEYWORD     = #{keyword_old} -> #{keyword}\n"
      end
      head << "-------------------------\n" unless head.empty?

      src = @db.text
      dst = latest_text
      diff_style = @options['diffmail.style'] || 0
      case diff_style.to_i
      when 0
	unified = @options['diffmail.lines'] || 3
	r = unified_diff( src, dst, unified )
      when 1
	r = word_diff_text( src, dst, true )
      end
    end
    send_updating_mail(@page, type, head + r) unless (head + r).empty?
  rescue
  end
end
