# $Id: local_css.rb,v 1.2 2004-03-01 09:50:45 hitoshi Exp $
# Copyright (C) 2003 OZAWA Sakuro <crouton@users.sourceforge.jp>

def about_local_css
  <<-EOS
!Description
When this plugin is installed, you can customize themes(CSSs) by
placing a local stylesheet file for each theme directory,
instead of editing original stylesheets themselves.
The local stylesheet is loaded after the original and
can overwrite CSS properties.
!Options
!!$options['local.css']
Local stylesheet to be read. Default: 'local.css'
  EOS
end

add_header_proc {
  local_css = $options['local.css'] || 'local.css'
  local_theme_url = theme_url.sub(/(.*\/).*\.css$/, "\\1#{local_css}")
  <<-EOS
  <link rel="stylesheet" type="text/css" href="#{$theme_url}/#{local_css}" media="all" />
  <link rel="stylesheet" type="text/css" href="#{local_theme_url}" media="all" />
  EOS
}

