# Copyright (C) 2007, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2. 

require "pstore"

module Bayes
	module CHARSET
		def self.setup_re(m)
			o = $KCODE
			$KCODE = m::KCODE
			m.const_set(:RE_MESSAGE_TOKEN, Regexp.union(m::RE_KATAKANA, m::RE_KANJI, /[a-zA-Z]+/))
			$KCODE=o
		end

		module EUC
			KCODE = "e"
			KATAKANA = "\xa5\xa2-\xa5\xf3"
			BAR = "\xa1\xbc"
			KANJI = "\xb0\xa1-\xfc\xfe"
			RE_KATAKANA = /[#{KATAKANA}#{BAR}]{2,}/eo
			RE_KANJI = /[#{KANJI}]{2,}/eo

			CHARSET.setup_re(self)
		end

		module UTF8
			KCODE = "u"
			def self.c2u(c)
				[c].pack("U")
			end
			def self.utf_range(a, b)
				"#{c2u(a)}-#{c2u(b)}"
			end
			KATAKANA = utf_range(0x30a0, 0x30ff)
			BAR = c2u(0x30fc)
			KANJI = utf_range(0x4e00, 0x9faf)
			RE_KATAKANA = /[#{KATAKANA}#{BAR}]{2,}/uo
			RE_KANJI = /[#{KANJI}]{2,}/uo

			CHARSET.setup_re(self)
		end
	end

	class TokenList < Array
		attr_reader :charset

		def initialize(charset=nil)
			unless charset
				charset =
					case $KCODE
					when /^e/i
						CHARSET::EUC
					else
						CHARSET::UTF8
					end
			end
			@charset = charset
		end

		alias _concat concat
		def concat(array, prefix=nil)
			if prefix
				_concat(array.map{|i| "#{prefix} #{i.to_s}"})
			else
				_concat(array)
			end
		end

		alias _push push
		def push(item, prefix=nil)
			if prefix
				_push("#{prefix} #{item.to_s}")
			else
				_push(item)
			end
		end

		def add_host(host, prefix=nil)
			if /^(?:\d{1,3}\.){3}\d{1,3}$/ =~ host
				while host.size>0
					push(host, prefix)
					host = host[/^(.*?)\.?\d+$/, 1]
				end
			else
				push(host, prefix)

				h = host
				while /^(.*?)[-_.](.*)$/=~h
					h = $2
					push($1, prefix)
					push(h, prefix)
				end
			end
			self
		end

		def add_url(url, prefix=nil)
			if %r[^(?:https?|ftp)://(.*?)(?::\d+)?/(.*?)\/?(\?.*)?$] =~ url
				host, path = $1, $2

				add_host(host, prefix)

				if path.size>0
					push(path, prefix)

					p = path
					re = %r[^(.*)[-_./](.*?)$]
					while re=~p
						p = $1
						push($2, prefix)
						push(p, prefix)
					end
				end
			end
			self
		end

		def add_message(message, prefix=nil)
			concat(message.scan(@charset::RE_MESSAGE_TOKEN), prefix)
			self
		end

		def add_mail_addr(addr, prefix=nil)
			push(addr, prefix)

			name, host = addr.split(/@/)
			return self if (name||"").empty?
			host ||= ""
			push(name, prefix)
			add_host(host, prefix)
			self
		end
	end

	class FilterBase
		attr_reader :spam, :ham, :db_name, :charset

		def initialize(db_name=nil, charset=nil)
			@spam = self.class::Corpus.new
			@ham = self.class::Corpus.new
			@charset = charset

			@db_name = db_name
			if db_name && File.exist?(db_name)
				PStore.new(db_name).transaction(true) do |db|
					@spam = db["spam"]
					@ham = db["ham"]
					@charset = db["charset"]
				end
			end
		end

		def save(db_name=nil)
			db_name ||= @db_name
			@db_name ||= db_name
			return unless @db_name
			PStore.new(@db_name).transaction do |db|
				db["spam"] = @spam
				db["ham"] = @ham
				db["charset"] = @charset
				yield(db) if block_given?
			end
		end

		def [](token)
			score(token)
		end
	end

	class PlainBayes < FilterBase
		class Corpus < Hash
			def initialize
				super(0.0)
			end

			def <<(src)
				s = src.size.to_f
				src.each do |i|
					self[i] += 1/s
				end
			end
		end

		def score(token)
			return nil unless @spam.include?(token) || @ham.include?(token)
			s = @spam[token]
			h = @ham[token]
			s/(s+h)
		end

		def estimate(tokens, take=15)
			s = tokens.uniq.map{|i| score(i)}.compact.sort{|a, b| (0.5-a).abs <=> (0.5-b)}.reverse[0...take]
			return nil if s.empty? || s.include?(1.0) && s.include?(0.0)

			prod = s.inject(1.0){|r, i| r*i}
			return prod/(prod+s.inject(1.0){|r, i| r*(1-i)})
		end
	end

	class PaulGraham < FilterBase
		class Corpus < Hash
			attr_reader :count
			def initialize
				super(0)
				@count = 0
			end

			def <<(src)
				@count += 1
				src.each do |i|
					self[i] += 1
				end
			end
		end

		def score(token)
			return 0.4 unless @spam.include?(token) or @ham.include?(token)
			g = @ham.count==0 ? 0.0 : [1.0, 2*@ham[token]/@ham.count.to_f].min
			b = @spam.count==0 ? 0.0 : [1.0, @spam[token]/@spam.count.to_f].min
			r = [0.01, [0.99, b/(g+b)].min].max
			r
		end

		def estimate(tokens, take=15)
			s = tokens.uniq.map{|i| score(i)}.compact.sort{|a, b| (0.5-a).abs <=> (0.5-b)}.reverse[0...take]
			return nil if s.empty? || s.include?(1.0) && s.include?(0.0)

			prod = s.inject(1.0){|r, i| r*i}
			return prod/(prod+s.inject(1.0){|r, i| r*(1-i)})
		end
	end
end
