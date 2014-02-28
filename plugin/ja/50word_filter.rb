# -*- coding: utf-8 -*-
# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

module WordFilterMessage
  def self.word_filter; "単語フィルタ"; end
  def self.use; "登録した正規表現でフィルタリングする"; end
  def self.regexp_by_line; "1行に1つずつ、正規表現を記述してください"; end
end
