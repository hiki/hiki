# $Id: rss.rb,v 1.4 2005-06-08 06:02:38 fdiary Exp $
# Copyright (C) 2003-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def label_rss_recent
  'Recent Changes'
end

def label_rss_config; 'RSS publication'; end
def label_rss_mode_title; 'Select the format.'; end
def label_rss_mode_candidate
  [ 'unified diff',
    'word diff (digest)',
    'word diff (full text)', ]
end
def label_rss_menu_title; 'add RSS menu'; end
def label_rss_menu_candidate
  [ 'Yes', 'No' ]
end
