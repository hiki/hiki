# $Id: session.rb,v 1.3 2004-08-09 06:44:49 fdiary Exp $
# Copyright (C) 2004 Kazuhiko <kazuhiko@fdiary.net>

module Hiki
  class Session
    attr_reader :session_id

    def initialize( conf, session_id = nil )
      @conf = conf
      if session_id
        if /[0-9a-f]{16}/ =~ session_id
          @session_id = session_id
        else
          @session_id = nil
        end
      else
        @session_id = create_new_id
        # remove old session files
        Dir.mkdir( session_path ) unless test( ?e,  session_path )
        Dir.glob( "#{session_path}/*" ).each do |file|
          File.delete( file.untaint )
        end
        # create a new session file
        File.new( session_file, 'w' ).close
      end
    end

    def check
      return false unless @session_id
      # a session will expire in 10 minutes
      if test( ?e, session_file ) && Time.now - File.mtime( session_file ) < 600
        File.new( session_file, 'w' ).close
        return true
      end
      false
    end

    private
    def session_path
      "#{@conf.data_path}session"
    end

    def session_file
      "#{session_path}/#{@session_id}".untaint
    end

    # (from cgi/session.rb)
    def create_new_id
      require 'digest/md5'
      md5 = Digest::MD5::new
      md5.update(String(Time::now))
      md5.update(String(rand(0)))
      md5.update(String($$))
      md5.update('foobar')
      md5.hexdigest[0,16]
    end
  end
end
