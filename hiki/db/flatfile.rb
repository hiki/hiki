# $Id: flatfile.rb,v 1.6 2004-04-18 07:22:50 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

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
    
    def store( page, text, md5 )
      filename = textdir( page )

      if exist?( page )
        return nil if md5 != md5hex( page )
        File::copy( filename, backupdir( page ) )
      end
      create_info_default( page ) unless info_exist?( page )

      File::open( filename, "w" ) do |f|
        f.write( text.gsub(/\r\n/, "\n") )
      end
      set_last_update( page, Time::now )
      true
    end

    def unlink( page )
      filename = textdir( page )
      if exist?( page )
        begin
          delete_info( page )
          File::unlink( filename )
        rescue
        end
      end
    end
    
    def touch( page )
      create_info_default( page ) unless info_exist?( page )
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
      Dir.glob( "#{$pages_path}/*" ).delete_if {|f| !test(?f, f.untaint)}.collect! {|f|
        File::basename( f ).unescape
      }
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

    def info( p )
      f = p.escape
      @info.transaction(true) do
        @info.root?(f) ? @info[f] : nil
      end
    end
    
    def page_info
      h = Array::new
      @info.transaction(true) do
        @info.roots.each { |a| h << {a.unescape => @info[a]} }
      end
      h
    end

    def set_attribute(p, attr)
      f = p.escape
      @info.transaction do
        attr.each do |attribute, value|
          @info[f][attribute] = value
        end
      end
    end

    def get_attribute(p, attribute)
      f = p.escape
      @info.transaction(true) do
        if @info.root?(f)
          @info[f][attribute] || default[attribute]
        else
          default[attribute]
        end
      end
    end

    def select
      result = []
      @info.transaction(true) do
        @info.roots.each do |a|
          result << a.unescape if yield(@info[a])
        end
      end
      result
    end
    
    def increment_hitcount ( p )
      f = p.escape
      @info.transaction do
        @info[f][:count] = @info[f][:count] + 1
      end
    end

    def get_hitcount( p )
      get_attribute(p, :count)
    end

    def freeze_page ( p, freeze )
      set_attribute(p, [[:freeze, freeze]])
    end

    def is_frozen? ( p )
      get_attribute(p, :freeze)
    end

    def set_last_update ( p, t )
      set_attribute(p, [[:last_modified, t]])
    end

    def get_last_update( p )
      get_attribute(p, :last_modified)
    end

    def set_references(p, r)
      set_attribute(p, [[:references, r.join(',')]])
    end

    def get_references(p)
      ref = []
      page_info.each do |a|
        ref << a.keys[0] if a.values[0][:references].split(',').index(p)
      end
      ref
    end

  private
    def delete_info(p)
      f = p.escape
      begin
        @info.transaction do
          @info.delete(f)
        end
      rescue
      end
    end
    
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
        :references     => '',
        :keyword        => [],
        :title          => '',
      }
    end

    def textdir(s)
      ( $pages_path + '/' + s.escape ).untaint
    end

    def backupdir(s)
     ( $backup_path  + '/' + s.escape ).untaint
    end
  end
end
