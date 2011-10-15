# append-css.rb: $Revision: 1.1 $
#
# Append CSS fragment via Preferences Page.
#
# Copyright (c) 2002 TADA Tadashi <sho@spc.gr.jp>
# Distributed under the GPL
#
add_header_proc do
  if @conf['append-css.css'] and !@conf['append-css.css'].empty?
    <<-HTML
    <style type="text/css"><!--
    #{CGI::escapeHTML( @conf['append-css.css'] )}
    --></style>
    HTML
  else
    ''
  end
end

add_conf_proc( 'append-css', append_css_label ) do
  if @mode == 'saveconf'
    @conf['append-css.css'] = @cgi.params['append-css.css'][0]
  end

  <<-HTML
  #{append_css_desc}
  <p><textarea name="append-css.css" cols="70" rows="15">#{CGI::escapeHTML( @conf['append-css.css'].to_s )}</textarea></p>
  HTML
end
