# $Id: trackback.rb,v 1.14 2006-10-05 06:46:43 fdiary Exp $
# Copyright (C) 2004 Kazuhiko <kazuhiko@fdiary.net>

def trackback
  script_name = ENV['SCRIPT_FILENAME']
  base_url = script_name.nil? || script_name.empty? ? '' : File.basename(script_name)
  <<-EOF
<div class="caption">TrackBack URL: <a href="#{base_url}/tb/#{escape(@page)}">#{@conf.base_url}#{base_url}/tb/#{escape(@page)}</a></div>
EOF
end

def trackback_post
  params     = @cgi.params
  url = params['url']
  unless 'POST' == @cgi.request_method && url
    redirect(@cgi, "#{@conf.index_url}?#{h(@page)}")
    return
  end
  blog_name = utf8_to_euc( params['blog_name'] || '' )
  title = utf8_to_euc( params['title'] || '' )
  excerpt = utf8_to_euc( params['excerpt'] || '' )

  lines = @db.load( @page )
  md5hex = @db.md5hex( @page )

  flag = false
  content = ''
  lines.each do |l|
    if /^\{\{trackback\}\}/ =~ l && flag == false
      content << "#{l}\n"
      content << %Q!* trackback : #{@conf.parser.link( url, "#{title} (#{blog_name})" )} (#{format_date(Time.now)})\n!
      content << @conf.parser.blockquote( shorten( excerpt ) )
      flag = true
    else
      content << l
    end
  end

  save( @page, content, md5hex )

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
  ::Hiki::Response.new(response, 200, head)
end
