# $Id: trackback.rb,v 1.1 2004-09-10 06:51:50 fdiary Exp $
# Copyright (C) 2004 Kazuhiko <kazuhiko@fdiary.net>

require 'uconv'

add_body_leave_proc do
  <<-EOF
<p>TrackBack URL: <a href="#{File.basename(ENV['SCRIPT_NAME'])}/tb/#{@page.escape}">#{base_url}#{File.basename(ENV['SCRIPT_NAME'])}/tb/#{@page.escape}</a></p>
  EOF
end if @options['trackback.enable']

def trackback
  params     = @cgi.params
  url = params['url'][0]
  unless /POST/i === @cgi.request_method && url
    redirect(@cgi, "#{@conf.index_page}?#{@page.escapeHTML}")
    return
  end
  blog_name = force_to_euc( params['blog_name'][0] || '' )
  title = force_to_euc( params['title'][0] || '' )
  excerpt = force_to_euc( params['excerpt'][0] || '' )
  body = <<-END

* trackback : [[#{title} (#{blog_name})|#{url}]]
#{excerpt.split(/\n/).collect{|s| %Q|""#{s}\n|}}
END

  content = @db.load( @page )
  md5hex = @db.md5hex( @page )

  @db.save( @page, content + body, md5hex )

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

def force_to_euc(str)
  begin
    str2 = Uconv.u8toeuc(str)
  rescue Uconv::Error
    str2 = NKF::nkf("-e", str)
  end
  return str2
end
