# $Id: storage.rb,v 1.6 2005-01-28 04:35:29 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'md5'
require 'hiki/util'

module Hiki
  class HikiDBBase
    attr_accessor :plugin, :text
    include Hiki::Util

    def open_db
      if block_given?
        yield
        close_db
      else
        true
      end
      true
    end

    def close_db
      true
    end
    
    def pages
      ['page1', 'page2', 'page3']
    end

    def save( page, src, md5 )
      @text = load(page) || ''
      result = store(page, src, md5)
      
      if result
        begin
          @plugin.update_proc
        rescue Exception
        end
      end
      result
    end

    def delete( page )
      text = load(page) || ''
      unlink(page)
      begin
        send_updating_mail(page, 'delete', text) if @conf.mail_on_update
      rescue
      end
    end
    
    def md5hex( page )
      s = load( page )
      MD5.new( s || '' ).hexdigest
    end

    def search( w )
      result  = Array::new
      keys    = w.split
      p       = pages
      total   = pages.size
      
      page_info.sort {|a, b| b.values[0][:last_modified] <=> a.values[0][:last_modified]}.each do |i|
        page = i.keys[0]
        info = i.values[0]
        keyword  = info[:keyword]
        title    = info[:title]
	status   = ''
        
	keys.each do |key|
	  quoted_key = Regexp::quote(key)
	  if keyword and keyword.join("\n").index(/#{quoted_key}/i)
	    status << @conf.msg_match_keyword.gsub(/\]/, " <strong>#{key.escapeHTML}</strong>]")
	  elsif title and title.index(/#{quoted_key}/i)
	    status << @conf.msg_match_title.gsub(/\]/, " <strong>#{key.escapeHTML}</strong>]")
	  elsif load( page ).index(/^.*#{quoted_key}.*$/i)
	    status << '[' + $&.escapeHTML.gsub(/#{Regexp::quote(key.escapeHTML)}/i) { "<strong>#{$&}</strong>"} + ']'
	  else
	    status = nil
	    break
	  end
        end
	result << [page, status] if status
      end

      [total, result]
    end
  end
end
