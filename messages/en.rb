# $Id: en.rb,v 1.2 2003-03-23 03:37:13 hitoshi Exp $
# en.rb
#
# Copyright (C) 2003 Masao Mutoh <mutoh@highway.ne.jp>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
# Original file is ja.rb:
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
module Hiki
  module Messages
    def msg_recent; ' Recent' end
    def msg_create; 'Create' end
    def msg_diff; 'Diff' end
    def msg_edit; 'Edit' end
    def msg_search; 'Search' end
    def msg_search_result; 'Search Results' end
    def msg_search_hits; '\'%1$s\': %3$d page(s) were found in %2$d pages.' end
    def msg_search_not_found; '\'%s\'was not found.' end
    def msg_search_comment; 'Search from whole this site. Ignore Upper/Lowere cases.' end
    def msg_frontpage; 'Top' end
    def msg_hitory; 'History' end
    def msg_index; 'Indexes' end
    def msg_recent_changes; 'Changes' end
    def msg_newpage; 'New' end
    def msg_no_recent; '<P>There are no data.</P>' end
    def msg_thanks; 'Thanks.' end
    def msg_save_conflict; 'Conflict your updating. Your changes wasn\'t saved. Copy your changes to your editor yourself. And reload the pages and edit it again.' end
    def msg_time_format; "%Y-%m-%d #DAY# %H:%M:%S" end
    def msg_date_format; "%Y-%m-%d " end
    def msg_day; %w(Sun Mon Tue Wed Thr Fri Sat) end
    def msg_preview; 'Confirm the result below, and save it with clicking Save button if there are no problem' end
    def msg_mail_on; 'Send updated-mail' end
    def msg_mail_off; 'Doesn\'t send updated-mail' end
    def msg_use; 'Use' end
    def msg_unuse; 'Doesn\'t use' end
    def msg_password_title; 'Admin\'s Password' end
    def msg_password_enter; 'Input Admin\'s password.' end
    def msg_password; 'Password' end
    def msg_ok; 'OK' end
    def msg_invalid_password; 'Password isn\'t correct. Your changes has not saved yet.' end
    def msg_save_config; 'Saved your changes' end
    def msg_freeze; 'This page is freezed. You need Admin\'s password for saving this page.' end
    def msg_freeze_mark; '[Freeze]' end
    def msg_already_exist; 'The page has already been existed.' end
    def msg_page_not_exist; 'The page is not exist. Please create it yourself:-)' end
    def msg_invalid_filename(s); "Include invalid character, or is over max length(#{s}byte). Change the page name." end
    def msg_delete; 'Deleted' end
    def msg_delete_page; 'The page deleted.' end
    def msg_follow_link; 'Click the anchor below to show your page: ' end
  end
end
