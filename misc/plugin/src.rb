# $Id: src.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def src_label
  'ソース'
end

def src
  sources = <<EOS
<!DOCTYPE html
    PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
  <meta http-equiv="Content-Language" content="ja">
  <meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
  <title id=title></title>
</head>
<body>
<pre>
EOS
  page = @db.load( @page )
  sources << (page ? page.escapeHTML : 'load error.')
  sources  << <<EOS
</pre>
</body>
</html>
EOS

  header = Hash::new
  header['Last-Modified'] = CGI::rfc1123_date(Time.now)
  header['type']          = 'text/html'
  header['charset']       = 'EUC-jp'
  header['Content-Language'] = $lang
  header['Pragma']           = 'no-cache'
  header['Cache-Control']    = 'no-cache'
  puts @cgi.header(header)
  puts sources

  nil # Don't move to the 'FrontPage'
end

add_body_enter_proc(Proc.new do
  add_plugin_command('src', src_label, {'p' => true})
end)
