# $Id: rss.rb,v 1.3 2005-03-03 12:56:54 fdiary Exp $
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
