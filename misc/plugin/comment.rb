# $Id: comment.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

# modified by yoshimi.

def comment_name_label
  'お名前'
end

def comment_comment_label
  'コメント'
end

def comment_post_label
  '投稿'
end

def comment_anonymous_label
  '名無しさん'
end

add_body_enter_proc(Proc.new do
  @comment_num = 0
  ""
end)

def comment(cols = 60, style = 0)
  cols = 60 unless cols.respond_to?(:integer?)
  style = 0 unless style.respond_to?(:integer?)
  style = 0 if style != 1

  @comment_num += 1
  <<EOS
<form action="#{$cgi_name}" method="post">
  <div>
    #{comment_name_label}:
    <input type="text" name="name" size="10">
    #{comment_comment_label}:
    <input type="text" name="msg" size="#{cols}">
    <input type="submit" name="comment" value="#{comment_post_label}">
    <input type="hidden" name="comment_no" value="#{@comment_num}">
    <input type="hidden" name="c" value="plugin">
    <input type="hidden" name="p" value="#{@page}">
    <input type="hidden" name="plugin" value="comment_post">
    <input type="hidden" name="style" value="#{style}">
  </div>
</form>
EOS
end

def comment_post
  params     = @cgi.params
  comment_no = (params['comment_no'][0] || 0).to_i
  name       = params['name'][0].size == 0 ? comment_anonymous_label : params['name'][0]
  msg        = params['msg'][0]
  style      = params['style'][0].to_i

  return '' if msg.strip.size == 0
  
  lines = @db.load( @page )
  md5hex = @db.md5hex( @page )
  
  flag = false
  count = 1

  content = ''
  lines.each do |l|
    if /^\{\{comment.*\}\}/ =~ l && flag == false
      if count == comment_no
        content << l if style == 1
        content << "*#{format_date(Time::now)} \'\'[[#{name}]]\'\' : #{msg}\n"
        content << l if style == 0
        flag = true
      else
        count += 1
        content << l
      end
    else
      content << l
    end
  end
  
  @db.save( @page, content, md5hex ) if flag
end
