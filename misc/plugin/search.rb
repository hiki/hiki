# search.rb - search plugin for Hiki
# Usage: just only {{search}} in your page.
# See http://www.usability.gr.jp/alertbox/20010513.html in detail.
# Copyright (C) 2003 Hajime BABA <baba.hajime@nifty.com>

def search_key_label
  '¸¡º÷¸ì¶ç'
end

def search_post_label
  '¸¡º÷'
end

def search
  <<EOS
<form action="#{@conf.cgi_name}" method="get">
  #{search_key_label}:<br>
  <input type="text" name="key" size="15">
  <input type="submit" name="comment" value="#{search_post_label}">
  <input type="hidden" name="c" value="search">
</form>
EOS
end

add_body_enter_proc(Proc.new do
  ""
end)
