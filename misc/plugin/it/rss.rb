# $Id: rss.rb,v 1.3 2005-03-03 15:53:56 fdiary Exp $
# Copyright (C) 2003 Luigi Maselli <metnik@tiscali.it>

def label_rss_recent
  'Ultime modifiche'
end

# PLEASE TRANSLATE
def label_rss_config; 'RSS publication'; end
def label_rss_mode_title; 'Select the format.'; end
def label_rss_mode_candidate
  [ 'unified diff',
    'word diff (digest)',
    'word diff (full text)', ]
end
