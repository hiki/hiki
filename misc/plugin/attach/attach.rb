# $Id: attach.rb,v 1.15 2005-03-03 15:53:55 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
#
# thanks to Kazuhiko, Masao Mutoh, SHIMADA Mitsunobu, Yoshimi, りた

def plugin_usage_label
       '<div><ul>
   <li>添付ファイルへのアンカは、{{attach_anchor(ファイル名 [, ページ名])}}</li>
   <li>添付したファイルの表示は、{{attach_view(ファイル名 [, ページ名])}}</li>
   <li>添付ページとファイルの一覧は、{{attach_map}}</li>
   </ul></div>'
end

def attach_form(s = '')
  command = @command == 'create' ? 'edit' : @command
  <<EOS
<div class="form">
<form class="nodisp" method="post" enctype="multipart/form-data" action="attach.cgi">
  <div>
    <input type="hidden" name="p" value="#{@page.escapeHTML}">
    <input type="hidden" name="command" value="#{command}">
    <input type="file" name="attach_file">
    <input type="submit" name="attach" value="#{attach_upload_label}">
  </div>
  <div>
    #{s}
  </div>
  #{plugin_usage_label}
</form>
</div>
EOS
end

def attach_map
  attach_files = attach_all_files
  return '' if attach_files.size == 0

  s = "<ul>\n"
  attach_files.sort do |a, b|
    a[0].unescape <=> b[0].unescape
  end.each do |attach_info|
    s << "<li>#{hiki_anchor(attach_info[0], attach_info[0].unescape.escapeHTML)}\n"
    s << "<ul>\n"
    attach_info[1].each do |f|
      s << "<li>#{attach_anchor(f, attach_info[0].unescape)}\n"
    end
    s << "</ul>\n"
  end
  s << "</ul>\n"
end

def attach_anchor_string(string, file_name, page=@page)
  s =  %Q!<a href="!
  s << %Q!#{@conf.cgi_name}#{cmdstr('plugin', "plugin=attach_download;p=#{page.escape};file_name=#{file_name.escape}")}">!
  s << %Q!#{if string then string.escapeHTML else file_name.escapeHTML end}</a>!
end

def attach_anchor(file_name, page=@page)
  s =  %Q!<a href="!
  s << %Q!#{@conf.cgi_name}#{cmdstr('plugin', "plugin=attach_download;p=#{page.escape};file_name=#{file_name.escape}")}">!
  s << %Q!#{file_name.escapeHTML}</a>!
end

def attach_image_anchor(file_name, page=@page)
  s =  %Q!<img alt="#{file_name.escapeHTML}" src="!
  s << %Q!#{@conf.cgi_name}#{cmdstr('plugin', "plugin=attach_download;p=#{page.escape};file_name=#{file_name.escape}")}">!
  s << %Q!</img>!
end

def attach_flash_anchor(file_name, page=@page)
  begin
    require 'image_size'
    f = "#{@cache_path}/attach/#{@page.escape}/#{file_name}"
    img_size = File.open(f,'rb'){|fh|
      is = ImageSize.new(fh)
      [is.get_width, is.get_height]
    }
  rescue
  end
  s =  %Q!<embed type="application/x-shockwave-flash" src="!
  s << %Q!#{@conf.cgi_name}#{cmdstr('plugin', "plugin=attach_download;p=#{page.escape};file_name=#{file_name}")}" !
  s << %Q! width="#{img_size[0]}" height="#{img_size[1]}" ! unless img_size.nil?
  s << %Q!>!
end

def attach_download
  mime_types = 
  {
    "gif"   => "image/gif",
    "txt"   => "text/plain",
    "rb"    => "text/plain",
    "rd"    => "text/plain",
    "c"     => "text/plain",
    "pl"    => "text/plain", 
    "py"    => "text/plain", 
    "sh"    => "text/plain", 
    "java"  => "text/plain",
    "html"  => "text/html",
    "htm"   => "text/html",
    "css"   => "text/css",
    "xml"   => "text/xml",
    "xsl"   => "text/xsl",
    "jpeg"  => "image/jpeg",
    "jpg"   => "image/jpeg",
    "png"   => "image/png",
    "bmp"   => "image/bmp",
    "doc"   => "application/msword",
    "xls"   => "application/vnd.ms-excel",
    "pdf"   => "application/pdf",
    "sql"   => "text/plain",
    "yaml"  => "text/plain", 
  }
  mime_types.default = "application/octet-stream"

  params      = @cgi.params
  page        = (params['p'][0] || '')
  file_name   = (params['file_name'][0] || '')
  attach_file = "#{@cache_path}/attach/#{page.escape}/#{file_name.escape}"
  extname     =  /\.([^.]+)$/.match(file_name.downcase).to_a[1]
  mime_type   = mime_types[extname]

  header = Hash::new
  header['Content-Type'] = mime_type
  header['Last-Modified'] = CGI::rfc1123_date(File.mtime(attach_file.untaint))
  header['Content-Disposition'] = %Q|attachment; filename="#{file_name.to_sjis}"; modification-date="#{header['Last-Modified']}";|
  print @cgi.header(header)
  print open(attach_file.untaint, "rb").read
  nil
end

def attach_src(file_name, page=@page)
  tabstop = ' ' * (@options['attach.tabstop'] ? @options['attach.tabstop'].to_i : 2)
  
  if file_name =~ /\.(txt|rd|rb|c|pl|py|sh|java|html|htm|css|xml|xsl|sql|yaml)\z/i
    file = "#{@conf.cache_path}/attach/#{page.untaint.escape}/#{file_name.untaint.escape}"
    s = %Q!<pre>!
    content = File::readlines(file)
    if @options['attach.show_linenum']
      line = 0
      content.collect! {|i| sprintf("%3d| %s", line+=1, i)}
    end
    s << content.join.escapeHTML.gsub(/^\t+/) {|t| tabstop * t.size}.to_euc
    s << %Q!</pre>!
  end
end

def attach_view(file_name, page=@page)
  if file_name =~ /\.(txt|rd|rb|c|pl|py|sh|java|html|htm|css|xml|xsl)\z/i
    attach_src(file_name, page)
  elsif file_name =~ /\.(jpeg|jpg|png|gif|bmp)\z/i
    attach_image_anchor(file_name, page)
  end
end

def attach_page_files
  result = Array::new
  attach_path = "#{@cache_path}/attach/#{@page.escape}".untaint
  if FileTest::directory?(attach_path)
    Dir.entries(attach_path).collect do |file_name|
      result << file_name if FileTest::file?("#{attach_path}/#{file_name}".untaint)
    end
  end
  result
end

def attach_all_files
  attach_files = Hash.new([])
  return [] unless test(?e, "#{@cache_path}/attach/")

  Dir.foreach("#{@cache_path}/attach/") do |dir|
    next if /^\./ =~ dir
    attach_files[File.basename(dir)] = Dir.glob("#{@cache_path}/attach/#{dir.untaint}/*").collect do |f|
      File.basename(f).unescape
    end
  end
  attach_files.to_a
end

def attach_show_page_files
  s = ''
  if (files = attach_page_files).size > 0
    s << %Q!<p>#{attach_files_label}: \n!
    files.each do |file_name|
      f = file_name.unescape
      case @conf.charset
      when 'EUC-JP'
	f = file_name.unescape.to_euc
      when 'Shift_JIS'
	f = file_name.unescape.to_sjis
      end
      s << %Q! [#{attach_anchor(f)}] !
    end
    s << "</p>\n"
  end
  s
end

def attach_show_page_files_checkbox
  s =  ''
  if (files = attach_page_files).size > 0
    s << %Q!<form method="post" enctype="multipart/form-data" action="attach.cgi">
  <input type="hidden" name="p" value="#{@page.escapeHTML}">
  <input type="hidden" name="command" value="#{@command == 'create' ? 'edit' : @command}">
  <p>#{attach_files_label}: 
!
    files.each do |file_name|
      f = file_name.unescape
      case @conf.charset
      when 'EUC-JP'
	f = file_name.unescape.to_euc
      when 'Shift_JIS'
	f = file_name.unescape.to_sjis
      end
      s << %Q! [<input type="checkbox" name="file_#{file_name}">#{attach_anchor(f)}] \n!
    end
    s << %Q!<input type="submit" name="detach" value="#{detach_upload_label}">\n</p>\n</form>\n!
  end
  s
end


add_body_leave_proc {
  begin
    s = case @options['attach.form']
    when 'view', 'both'
      attach_form(attach_show_page_files)
    else
      ''
    end
  rescue Exception
  end
}
  
add_form_proc {
  begin
    s = case @options['attach.form']
    when 'edit', 'both'
      attach_form(attach_show_page_files_checkbox)
    else
      ''
    end
  rescue Exception
  end
}
