# $Id: global.rb,v 1.2 2003-02-22 06:18:00 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

$cgi_name        = 'hiki.cgi'
$template_path   = "template/#{$lang}"
$plugin_path     = 'plugin'
$theme_path      = 'theme'
$cache_path      = "#{$data_path}/cache"
$config_file     = "#{$data_path}/hiki.conf"

$side_menu       = 'SideMenu'
$interwiki_name  = 'InterWikiName' 
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
