# $Id: bbs.rb,v 1.4 2004-08-06 15:31:57 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def bbs_name_label
  'お名前'
end

def bbs_subject_label
  '件名'
end

def bbs_post_label
  '投稿'
end

def bbs_anonymous_label
  '名無しさん'
end

def bbs_notitle_label
  '無題'
end

add_body_enter_proc(Proc.new do
  @bbs_num = 0
  ""
end)

def bbs
  @bbs_num += 1
  <<EOS
<form action="#{@conf.cgi_name}" method="post">
  <div>
    #{bbs_name_label}: <input type="text" name="name" size="10">
    #{bbs_subject_label}: <input type="text" name="subject" size="40"><br>
    <textarea cols="60" rows="8" name="msg" size="40"></textarea><br>
    <input type="submit" name="comment" value="#{bbs_post_label}">
    <input type="hidden" name="bbs_num" value="#{@bbs_num}">
    <input type="hidden" name="c" value="plugin">
    <input type="hidden" name="p" value="#{@page.escapeHTML}">
    <input type="hidden" name="plugin" value="bbs_post">
  </div>
</form>
EOS
end

def bbs_post
  params     = @cgi.params
  bbs_num    = (params['bbs_num'][0] || 0).to_i
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
    if /^\{\{bbs\}\}/ =~ l && flag == false
      if count == bbs_num
        content << "#{l}\n"
        content << "!#{subject} - #{name} (#{format_date(Time::now)})\n"
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
  
  @db.save( @page, content, md5hex ) if flag
end
