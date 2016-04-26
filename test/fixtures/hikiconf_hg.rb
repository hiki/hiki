# -*- coding: utf-8 -*-
require "pathname"
fixtures_dir = Pathname(__FILE__.tr("()", "")).dirname

@data_path       = (fixtures_dir + "hg_data").expand_path.to_s
@smtp_server     = "localhost"
@use_plugin      = true
@use_session     = true
@site_name       = "Test Wiki"
@author_name     = "名無しさん"
@mail_on_update  = false
@mail            = ["hoge@example.net"]
@theme           = "hiki"
@theme_url       = "theme"
@theme_path      = "theme"
@use_sidebar     = true
@main_class      = "main"
@sidebar_class   = "sidebar"
@auto_link       = false
@use_wikiname    = true
@xmlrpc_enabled  = true
@repos_type      = "hg"

#=========================================
#  変更可能項目
#=========================================

# @cgi_name        = 'hiki.cgi'
# @base_url        = "http://example.com/hiki/"
# @cache_path      = "#{@data_path}/cache"
# @template_path   = 'template'
# @style           = 'default'
# @mail_from       = 'from@mail.address.hoge'
# @hilight_keys    = true

# @charset         = 'UTF-8'

# @timeout         = 30

# @plugin_debug    = false

@options         = {}                    # この行は変更しないでください。

