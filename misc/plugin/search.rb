# search.rb - search plugin for Hiki
# Usage: just only {{search_form}} in your page.
# See http://www.usability.gr.jp/alertbox/20010513.html in detail.
# Copyright (C) 2003 Hajime BABA <baba.hajime@nifty.com>

def search_form
  <<EOS
<form action="#{@conf.cgi_name}" method="get">
  <input type="text" name="key" size="15">
  <input type="submit" name="comment" value="#{search_post_label}">
  <input type="hidden" name="c" value="search">
</form>
EOS
end

export_plugin_methods( :search_form )

unless respond_to?( :search )
  alias :search :search_form
  export_plugin_methods( :search, :search_form )
end
