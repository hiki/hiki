# $Id: global.rb,v 1.6 2004-06-19 09:20:14 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

# default values
$index_page    ||= ''
$smtp_server   ||= 'localhost'
$use_plugin    ||= false
$site_name     ||= 'hoge hoge'
$author_name   ||= ''
$main_on_update||= false
$mail          ||= ''
$theme         ||= 'hiki'
$theme_url     ||= 'theme'
$theme_path    ||= 'theme'
$use_sidebar   ||= false
$main_class    ||= 'main'
$sidebar_class ||= 'sidebar'
$auto_link     ||= false
$cache_path    ||= "#{$data_path}/cache"
$style         ||= 'default'
$hilight_keys  ||= true
$plugin_debug  ||= false
$charset       ||= 'EUC-JP'
$lang          ||= 'ja'
$database_type ||= 'flatfile'
$cgi_name      ||= './'
$options         = {} unless $options.class == Hash

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
