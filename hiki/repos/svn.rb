# $Id: svn.rb,v 1.2 2005-01-21 13:50:21 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require 'hiki/repos/default'

# Subversion Repository Backend
module Hiki
  class ReposSvn < ReposDefault
     def setup()
	system( "svnadmin create #{@root} > /dev/null 2>&1" )
     end
     def imported?( wiki )
	s = ''
	open("|svn ls file://#{@root}/#{wiki}") do |f|
	   s << (f.gets( nil ) ? $_ : '')
	end

	if %r|^trunk/$| =~ s then
	   return true
	else
	   return false
	end
     end
     def import( wiki )
	oldpwd = Dir.pwd
	begin
	   Dir.chdir( "#{@data_path}/#{wiki}/text" )
	   system( "svnadmin create #{@root}/#{wiki} > /dev/null 2>&1" )
	   system( "svn import -m 'Starting #{wiki} from #{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' . file://#{@root}/#{wiki}/trunk > /dev/null 2>&1".untaint )
	   Dir.chdir( '..' )
	   rmdir( 'text' )
	   system( "svn checkout file://#{@root}/#{wiki}/trunk text > /dev/null 2>&1" )
	   system( "svn propdel svn:mime-type -R text > /dev/null 2>&1" )
	ensure
	   Dir.chdir( oldpwd.untaint )
	end
     end
     def update( wiki )
	oldpwd = Dir.pwd
	begin
	   Dir.chdir( "#{@data_path}/#{wiki}/text" )
	   system( "svn update > /dev/null 2>&1" )
	ensure
	   Dir.chdir( oldpwd.untaint )
	end
     end
     def commit( page )
       oldpwd = Dir.pwd.untaint
       begin
	 Dir.chdir( "#{@data_path}/text" )
	 system( "svn add -- #{page.escape} > /dev/null 2>&1".untaint )
	 system( "svn propdel svn:mime-type -- #{page.escape} > /dev/null 2>&1".untaint )
	 system( "svn ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint )
       ensure
	 Dir.chdir( oldpwd )
       end
     end
     def delete( page )
       oldpwd = Dir.pwd.untaint
       begin
	 Dir.chdir( "#{@data_path}/text" )
	 system( "svn remove -- #{page.escape} > /dev/null 2>&1".untaint )
	 system( "svn ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint )
       ensure
	 Dir.chdir( oldpwd )
       end
     end
  end
end
