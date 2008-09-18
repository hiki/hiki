# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2. 

class BayesFilterConfig
  module Res
    def self.label; "ベイズフィルタ"; end
    def self.submitted_pages; "投稿されたページデータ一覧"; end
    def self.submitted_page_diff; "投稿されたページの差分"; end
    def self.spam_rate; "スパム率"; end
    def self.title; "タイトル"; end
    def self.diff_text; "本文追加部分"; end
    def self.diff_keyword; "追加キーワード"; end
    def self.remote_addr; "リモートアドレス"; end
    def self.register_as_ham; "ハムとして登録"; end
    def self.register_as_spam; "スパムとして登録"; end
    def self.success_process_page_data; "投稿ページデータを処理しました"; end
    def self.ham_tokens; "ハムのトークン一覧"; end
    def self.spam_tokens; "スパムのトークン一覧"; end
    def self.token; "トークン"; end
    def self.score; "スパム率"; end
    def self.old_text; "更新前本文"; end
    def self.new_text; "更新後本文"; end
    def self.rebuild_db; "ベイズフィルタ用データベースを再構築する"; end
    def self.remote_addr; "リモートホストアドレス"; end
    def self.other; "その他"; end
    def self.use_filter; "ベイズフィルタを使う"; end
    def self.threshold; "閾値"; end
    def self.page_token; "ページ中のトークン一覧"; end
    def self.report_filtering; "フィルタリング結果をメールで通知"; end
    def self.share_db; "共用データベースを使う"; end
    def self.limit_of_submitted_pages; "一度に表示する投稿ページデータの数"; end
	 def self.difference; "差分"; end
  end
end
