# $Id: rss.rb,v 1.3 2005-09-05 12:18:06 yanagita Exp $
# Copyright (C) 2003-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def label_rss_recent
  '更新日時順'
end

def label_rss_config; 'RSS の作成'; end
def label_rss_mode_title; 'RSS のフォーマット'; end
def label_rss_mode_candidate
  [ 'unified diff 形式',
    'word diff 形式 (ダイジェスト)',
    'word diff 形式 (全文)',
    'タイトルのみ',
  ]
end
def label_rss_menu_title; 'RSS メニューの表示'; end
def label_rss_menu_candidate
  [ 'する', 'しない' ]
end
