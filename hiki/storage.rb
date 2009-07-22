# $Id: storage.rb,v 1.17 2006-11-25 22:13:28 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'digest/md5'
require 'hiki/util'

module Hiki
  class HikiDBBase
    attr_accessor :text
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

    def backup( page )
      @text = load( page ) || ''
    end

    def delete( page )
      backup( page )
      unlink( page )
      delete_cache( page )
      begin
        send_updating_mail(page, 'delete', text) if @conf.mail_on_update
      rescue
      end
    end
    
    def md5hex( page )
      s = load( page )
      Digest::MD5::hexdigest( s || '' )
    end

    def search( w )
      result  = Array::new
      keys    = w.split
      p       = pages
      total   = pages.size
      
      page_info.sort_by {|e| e.values[0][:last_modified]}.reverse_each do |i|
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

    def load_cache( page )
      Dir.mkdir( @conf.cache_path ) unless test( ?e, @conf.cache_path )
      cache_path = "#{@conf.cache_path}/parser"
      Dir.mkdir( cache_path ) unless test( ?e, cache_path )
      begin
        tmp = Marshal::load( File.open( "#{cache_path}/#{CGI::escape( page )}".untaint, 'rb' ) {|f| f.read} )
	if tmp[0] == Hiki::RELEASE_DATE
	  return tmp[1]
	else
	  return nil
	end
      rescue
        return nil
      end
    end

    def save_cache( page, tokens )
      begin
        File.open( "#{@conf.cache_path}/parser/#{CGI::escape( page )}".untaint, 'wb') do |f|
          Marshal::dump([Hiki::RELEASE_DATE, tokens], f)
        end
      rescue
      end
    end

    def delete_cache( page )
      begin
        File.unlink("#{@conf.cache_path}/parser/#{CGI::escape( page )}".untaint)
      rescue Errno::ENOENT
      end
    end
  end
end
