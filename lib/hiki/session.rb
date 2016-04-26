# Copyright (C) 2004 Kazuhiko <kazuhiko@fdiary.net>

module Hiki
  class Session
    MAX_AGE = 60 * 60

    attr_reader :session_id
    attr_writer :user

    def initialize(conf, session_id = nil, max_age = MAX_AGE)
      @conf = conf
      @max_age = max_age
      if session_id
        if /\A[0-9a-f]{16}\z/ =~ session_id
          @session_id = session_id
        else
          @session_id = nil
        end
      else
        @session_id = create_new_id
        # remove old session files
        Dir.mkdir(session_path) unless test(?e,  session_path)
        Dir.glob("#{session_path}/*").each do |file|
          file.untaint
          File.delete(file) if Time.now - File.mtime(file) > @max_age
        end
      end
    end

    def save
      File.open(session_file, "w") do |file|
        file.print @user.to_s
      end
    end

    def user
      return nil unless check
      begin
        user = File.read(session_file)
        user = nil if user.empty?
      rescue
        user = nil
      end
      user
    end

    def check
      return false unless @session_id
      # a session will expire in 10 minutes
      if test(?e, session_file) && Time.now - File.mtime(session_file) < @max_age
        now = Time.now
        File.utime(now, now, session_file)
        return true
      end
      false
    end

    def delete
      begin
        File.delete(session_file)
      rescue Errno::ENOENT
      end
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
      require "digest/md5"
      md5 = Digest::MD5.new
      now = Time.now
      md5.update(now.to_s)
      md5.update(String(now.usec))
      md5.update(String(rand(0)))
      md5.update(String($$))
      md5.update("foobar")
      md5.hexdigest[0,16]
    end
  end
end
