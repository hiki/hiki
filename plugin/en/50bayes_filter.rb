# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2. 

class BayesFilterConfig
  module Res
    def self.label; "Bayes filter"; end
    def self.submitted_pages; "Submitted pages"; end
    def self.submitted_page_diff; "Diff of submitted page"; end
    def self.spam_rate; "spam rate"; end
    def self.title; "Title"; end
    def self.diff_text; "Appended text"; end
    def self.diff_keyword; "Appended keywords"; end
    def self.remote_addr; "remote address"; end
    def self.register_as_ham; "register as ham"; end
    def self.register_as_spam; "register as spam"; end
    def self.success_process_page_data; "Success processing page data"; end
    def self.ham_tokens; "Tokens of ham"; end
    def self.spam_tokens; "Tokens of spam"; end
    def self.token; "token"; end
    def self.score; "score"; end
    def self.old_text; "text(old)"; end
    def self.new_text; "text(new)"; end
    def self.rebuild_db; "Rebuild DataBase of BayesFilter"; end
    def self.remote_addr; "Remote host address"; end
    def self.other; "other"; end
    def self.use_filter; "Use Bayes filter"; end
    def self.threshold; "Threshold"; end
    def self.page_token; "Tokens of page"; end
    def self.report_filtering; "Report filtering result by mail"; end
    def self.share_db; "Use shared database"; end
    def self.limit_of_submitted_pages; "Limit of submitted pages to show at one time"; end
	 def self.difference; "Difference"; end
  end
end
