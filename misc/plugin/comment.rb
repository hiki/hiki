# $Id: comment.rb,v 1.14 2006-10-05 06:46:43 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

# modified by yoshimi.

add_body_enter_proc(Proc.new do
  @comment_num = 0
  ""
end)

def comment(cols = 60, style = 0)
  return '' if @conf.use_session && !@session_id

  cols = 60 unless cols.respond_to?(:integer?)
  style = 0 unless style.respond_to?(:integer?)
  style = 0 if style != 1
  @comment_num += 1
  name = @user || ''
  <<EOS
<form action="#{@conf.cgi_name}" method="post">
  <div>
    #{comment_name_label}:
    <input type="text" name="name" value="#{name}" size="10">
    #{comment_comment_label}:
    <input type="text" name="msg" size="#{cols}">
    <input type="submit" name="comment" value="#{comment_post_label}">
    <input type="hidden" name="comment_no" value="#{@comment_num}">
    <input type="hidden" name="c" value="plugin">
    <input type="hidden" name="p" value="#{@page.escapeHTML}">
    <input type="hidden" name="plugin" value="comment_post">
    <input type="hidden" name="style" value="#{style}">
    <input type="hidden" name="session_id" value="#{@session_id}">
  </div>
</form>
EOS
end

def comment_post
  return '' if @conf.use_session && @session_id != @cgi['session_id']

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
    if /^\{\{r?comment.*\}\}/ =~ l && flag == false
      if count == comment_no
        content << l if style == 1
        content << "*#{format_date(Time::now)} #{name} : #{msg}\n"
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
  
  save( @page, content, md5hex ) if flag
end

def rcomment(cols = 60)
  comment(cols, 1)
end
