# $Id: storage.rb,v 1.2 2003-02-22 06:18:00 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'md5'
require 'hiki/util'

module Hiki
  class HikiDBBase
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

    def md5hex ( page )
      s = load ( page )
      MD5.new( s ).hexdigest
    end

    def diff( page )
      latest = (f = load( page )) ? f : ''

      if backup_exist?( page )
        old = load_backup ( page )
      else
        old = ''
      end

      diff_t( old, latest )
    end

    def search( w )
      result  = Array::new
      keyword = Regexp::quote( w )
      p       = pages
      total   = pages.size
      p.each {|pg|
        result << pg if load( pg ).index(/#{keyword}/i) || /#{keyword}/i =~ pg
      }
      [total, result]
    end
  end
end
