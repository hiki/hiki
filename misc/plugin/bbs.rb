# $Id: bbs.rb,v 1.14 2006-10-05 06:46:43 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

add_body_enter_proc(Proc.new do
  @bbs_num = 0
  ""
end)

def bbs(level = 1)
  return '' if @conf.use_session && !@session_id

  @bbs_num += 1
  name = @user || ''
  level = (Integer(level) rescue 1)

  <<EOS
<form action="#{@conf.cgi_name}" method="post">
  <div>
    #{bbs_name_label}: <input type="text" name="name" value="#{name.escapeHTML}" size="10">
    #{bbs_subject_label}: <input type="text" name="subject" size="40"><br>
    <textarea cols="60" rows="8" name="msg"></textarea><br>
    <input type="submit" name="comment" value="#{bbs_post_label}">
    <input type="hidden" name="bbs_num" value="#{@bbs_num}">
    <input type="hidden" name="bbs_level" value="#{level}">
    <input type="hidden" name="c" value="plugin">
    <input type="hidden" name="p" value="#{@page.escapeHTML}">
    <input type="hidden" name="plugin" value="bbs_post">
    <input type="hidden" name="session_id" value="#{@session_id}">
  </div>
</form>
EOS
end

def bbs_post
  return '' if @conf.use_session && @session_id != @cgi['session_id']

  params     = @cgi.params
  bbs_num    = (params['bbs_num'][0] || 0).to_i
  bbs_level  = (params['bbs_level'][0] || 1).to_i
  name       = params['name'][0].size == 0 ? bbs_anonymous_label : params['name'][0]
  subject    = (params['subject'][0].size == 0 ? bbs_notitle_label : params['subject'][0])
  msg        = params['msg'][0]

  return '' if msg.strip.size == 0
  
  lines = @db.load( @page )
  md5hex = @db.md5hex( @page )
  
  flag = false
  count = 1

  content = ''
  lines.each do |l|
    if /^\{\{bbs\b(:?[^\}]*)?\}\}/ =~ l && flag == false
      if count == bbs_num
        content << "#{l}\n"
        content << @conf.parser.heading( "#{subject} - #{name} (#{format_date(Time::now)})\n", bbs_level )
        content << "#{msg}\n"
        content << "{{comment}}\n"
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
