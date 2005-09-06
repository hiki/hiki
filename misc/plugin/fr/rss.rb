# $Id: rss.rb,v 1.4 2005-09-06 06:08:29 fdiary Exp $
# Copyright (C) 2003 Laurent Sansonetti <laurent@datarescue.be>

def label_rss_recent
  'Modifications récentes'
end

# PLEASE TRANSLATE
def label_rss_config; 'RSS publication'; end
def label_rss_mode_title; 'Select the format.'; end
def label_rss_mode_candidate
  [ 'unified diff',
    'word diff (digest)',
    'word diff (full text)',
    'HTML (full text)', ]
end
