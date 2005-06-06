# $Id: trackback.rb,v 1.6 2005-06-06 11:58:13 yanagita Exp $
# Copyright (C) 2004 Kazuhiko <kazuhiko@fdiary.net>

require 'uconv'

def trackback
  <<-EOF
<div class="caption">TrackBack URL: <a href="#{File.basename(ENV['SCRIPT_NAME'])}/tb/#{@page.escape}">#{@conf.base_url}#{File.basename(ENV['SCRIPT_NAME'])}/tb/#{@page.escape}</a></div>
EOF
end

def trackback_post
  params     = @cgi.params
  url = params['url'][0]
  unless /POST/i === @cgi.request_method && url
    redirect(@cgi, "#{@conf.index_url}?#{@page.escapeHTML}")
    return
  end
  blog_name = Hiki::Util::utf8_to_euc( params['blog_name'][0] || '' )
  title = Hiki::Util::utf8_to_euc( params['title'][0] || '' )
  excerpt = Hiki::Util::utf8_to_euc( params['excerpt'][0] || '' )

  lines = @db.load( @page )
  md5hex = @db.md5hex( @page )

  flag = false
  content = ''
  lines.each do |l|
    if /^\{\{trackback\}\}/ =~ l && flag == false
      content << "#{l}\n"
      content << %Q!* trackback : [[#{title} (#{blog_name})|#{url}]] (#{format_date(Time::now)})\n!
      content << %Q!#{shorten(excerpt).split(/\n/).collect{|s| %Q|""#{s}\n|}}\n!
      flag = true
    else
      content << l
    end
  end

  @db.save( @page, content, md5hex )

  response = <<-END
<?xml version="1.0" encoding="iso-8859-1"?>
<response>
<error>0</error>
</response>
END
  head = {
    'type' => 'text/xml',
    'Vary' => 'User-Agent'
  }
  head['Content-Length'] = response.size.to_s
  head['Pragma'] = 'no-cache'
  head['Cache-Control'] = 'no-cache'
  print @cgi.header( head )
  print response
end
