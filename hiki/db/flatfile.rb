# $Id: flatfile.rb,v 1.1.1.1 2003-02-22 04:39:31 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

require 'ftools'
require 'time'
require 'hiki/db/ptstore'
require 'hiki/storage'
require 'hiki/util'

module Hiki
  class HikiDB < HikiDBBase
    def initialize
      create_infodb unless test(?e, $info_db)
      @info = PTStore::new( $info_db )
    end
    
    def save( page, text, md5 )
      filename = textdir( page )

      if exist?( page )
        return nil if md5 != md5hex( page )
        File::copy( filename, backupdir( page ) )
      end
      create_info_default( page ) unless info_exist?( page )

      File::open( filename, "w" ) do |f|
        f.write( text )
      end
      true
    end

    def touch( page )
      create_info_default( page ) unless info_exist? ( page )
      filename = textdir( page )
      File::open( filename, "w" ) {|f|}
    end

    def load( page )
      return nil unless exist?( page )
      filename = textdir( page )
      File::readlines( filename ).join
    end

    def load_backup( page )
      return nil unless backup_exist?( page )
      filename = backupdir( page )
      File::readlines( filename ).join
    end

    def exist?( page )
      filename = textdir( page )
      test( ?e,  filename )
    end

    def backup_exist?( page )
      filename = backupdir( page )
      test( ?e,  filename )
    end

    def pages
      Dir.glob( "#{$pages_path}/*" ).collect! {|f| File::basename( f ).unescape}
    end

    # ==============
    #   info DB
    # ==============
    def create_infodb
      @info = PTStore::new( $info_db )
      @info.transaction do
        pages.each do |a|
          r = default
          r[:last_modified] = File::mtime( "#{$pages_path}/#{a.escape}".untaint )
          @info[a.escape]  = r
        end
      end
    end
    
    def info_exist? ( p )
      f = p.escape
      @info.transaction(true) do
        @info.root?( f )
      end
    end
    
    def infodb_exist?
      test( ?e, $info_db )
    end

    def increment_hitcount ( p )
      f = p.escape
      @info.transaction do
        @info[f][:count] = @info[f][:count] + 1
      end
    end

    def get_hitcount( p )
      f = p.escape
      @info.transaction(true) do
        @info.root?(f) ? @info[f][:count] : default[:count]
      end
    end
      
    def freeze_page ( p, freeze )
      f = p.escape
      @info.transaction do
        @info[f][:freeze] = freeze
      end
    end

    def is_frozen? ( p )
      f = p.escape
      @info.transaction(true) do
        @info.root?(f) ? @info[f][:freeze] : default[:freeze]
      end
    end

    def set_last_update ( p, t )
      f = p.escape
      @info.transaction do
        @info[f][:last_modified] = t
      end
    end

    def get_last_update( p )
      f = p.escape
      @info.transaction(true) do
        @info.root?(f) ? @info[f][:last_modified] : default[:last_modified]
      end
    end

    def page_info
      h = Array::new
      @info.transaction(true) do
        @info.roots.each { |a| h << {a.unescape => @info[a]} }
      end
      h
    end

    def set_references(p, r)
      f = p.escape
      @info.transaction do
        @info[f][:references] = r.join(',')
      end
    end

    def get_references(p)
      ref = []
      page_info.each do |a|
        ref << a.keys[0] if a.values[0][:references].split(',').index(p)
      end
      ref
    end

  private
    def create_info_default(p)
      f = p.escape
      @info.transaction do
        @info[f] = default
      end
    end
    
    def default
      { :count          => 0,
        :last_modified  => Time::now,
        :freeze         => false,
        :references     => ''
      }
    end

    def textdir(s)
      ( $pages_path  + '/' + s.escape ).untaint
    end

    def backupdir(s)
     ( $backup_path  + '/' + s.escape).untaint
    end
  end
end
