# Copyright (C) 2004 Kazuhiko <kazuhiko@fdiary.net>

def trackback
  script_name = ENV['SCRIPT_FILENAME']
  base_url = script_name.nil? || script_name.empty? ? '' : File.basename(script_name)
  <<-EOF
<div class="caption">TrackBack URL: <a href="#{base_url}/tb/#{escape(@page)}">#{@conf.base_url}#{base_url}/tb/#{escape(@page)}</a></div>
EOF
end

def trackback_post
  params     = @request.params
  url = params['url']
  unless 'POST' == @request.request_method && url
    return redirect(@request, "#{@conf.index_url}?#{h(@page)}")
  end
  blog_name = params['blog_name'] || ''
  title = params['title'] || ''
  excerpt = params['excerpt'] || ''

  lines = @db.load( @page )
  md5hex = @db.md5hex( @page )

  flag = false
  content = ''
  lines.each_line do |line|
    if /^\{\{trackback\}\}/ =~ line && flag == false
      content << "#{line}\n"
      content << %Q!* trackback : #{@conf.parser.link( url, "#{title} (#{blog_name})" )} (#{format_date(Time.now)})\n!
      content << @conf.parser.blockquote( shorten( excerpt ) )
      flag = true
    else
      content << line
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
