# $Id: global.rb,v 1.4 2004-06-18 13:59:32 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

$template_path   = "#{$path}/template/#{$lang}"
$plugin_path     = "#{$path}/plugin"
$config_file     = "#{$data_path}/hiki.conf"

$side_menu       = 'SideMenu'
$interwiki_name  = 'InterWikiName' 
$aliaswiki_name  = 'AliasWikiName' 
$formatting_rule = 'TextFormattingRules'

# 'flat file database'
$pages_path      = "#{$data_path}/text"
$backup_path     = "#{$data_path}/backup"
$info_db         = "#{$data_path}/info.db"

$template        = {'view'    => 'view.html',
                   'index'   => 'list.html',
                   'edit'    => 'edit.html',
                   'recent'  => 'list.html',
                   'diff'    => 'diff.html',
                   'search'  => 'form.html',
                   'create'  => 'form.html',
                   'admin'   => 'adminform.html',
                   'save'    => 'success.html',
                   'password'=> 'form.html'
                  }
                  
$max_name_size   = 50 
$password        = ''

$theme_url     ||= 'theme'
$theme_path    ||= 'theme'
$main_class    ||= 'main'
$sidebar_class ||= 'sidebar'
$auto_link     ||= false
$style         ||= 'default'
$hilight_keys  ||= true
$cgi_name      ||= 'hiki.cgi'
$plugin_debug  ||= false
