# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

module Hiki::Filter
  add_filter do |new_page, old_page, posted_by_user|
    next if posted_by_user
    next unless @conf["word_filter.use"]

    spam = false
    @conf["word_filter.words"].split(/\n/).each do |w|
      next if w.empty?
      re = /#{w.chomp}/
      [:page, :title, :text, :keyword].each do |m|
        str = (new_page.send(m)||"")
        str = str.join("\n") if str.is_a?(Array)
        next if str.empty?
        spam = true if str=~re
      end
      next if spam
    end
    spam
  end
end
