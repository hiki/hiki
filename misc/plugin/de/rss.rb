# $Id: rss.rb,v 1.2 2005-09-06 06:08:29 fdiary Exp $
# Copyright (C) 2003-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def label_rss_recent
  'Letzte &Auml;nderungen'
end

def label_rss_config; 'RSS Publikation'; end
def label_rss_mode_title; 'Formatauswahl.'; end
def label_rss_mode_candidate
  [ 'unified diff',
    'word diff (Auszug)',
    'word diff (voller Text)',
    'HTML (voller Text)', ]
end
def label_rss_menu_title; 'RSS Men&uuml; hinzuf&uuml;gen'; end
def label_rss_menu_candidate
  [ 'Ja', 'Nein' ]
end
