# $Id: cvs.rb,v 1.3 2005-05-17 05:33:08 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require 'hiki/repos/default'

# CVS Repository Backend
module Hiki
  class ReposCvs < ReposDefault
     def setup()
        oldpwd = Dir.pwd
        begin
           Dir.chdir( @data_path )
           system( "cvs -d #{@root} init > /dev/null 2>&1" )
           if not File.directory?(".CVSROOT") then
              system( "cvs -d #{@root} co -d .CVSROOT CVSROOT > /dev/null 2>&1" )
           end
           Dir.chdir( ".CVSROOT" )
           system( "cvs -d #{@root} update > /dev/null 2>&1" )
        ensure
           Dir.chdir( oldpwd.untaint )
        end
     end
     def imported?( wiki )
        return File.directory?( "#{@root}/#{wiki}" )
     end
     def import( wiki )
        oldpwd = Dir.pwd
        begin
           Dir.chdir( "#{@data_path}/#{wiki}/text" )
           system( "cvs -d #{@root} import -m 'Starting #{wiki} from #{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' #{wiki} T#{wiki} start > /dev/null 2>&1".untaint )
           Dir.chdir( '..' )
           system( "cvs -d #{@root} co -d text #{wiki} > /dev/null 2>&1" )
        ensure
           Dir.chdir( oldpwd.untaint )
        end
     end
     def update( wiki )
        oldpwd = Dir.pwd
        begin
           Dir.chdir( "#{@data_path}/#{wiki}/text" )
           system( "cvs -d #{@root} update > /dev/null 2>&1" )
        ensure
           Dir.chdir( oldpwd.untaint )
        end
     end
     def commit( page )
       oldpwd = Dir.pwd.untaint
       begin
         Dir.chdir( "#{@data_path}/text" )
         system( "cvs -d #{@root} add -- #{page.escape} > /dev/null 2>&1".untaint )
         system( "cvs -d #{@root} ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint )
       ensure
         Dir.chdir( oldpwd )
       end
     end
     def delete( page )
       oldpwd = Dir.pwd.untaint
       begin
         Dir.chdir( "#{@data_path}/text" )
         system( "cvs -d #{@root} remove -- #{page.escape} > /dev/null 2>&1".untaint )
         system( "cvs -d #{@root} ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint )
       ensure
         Dir.chdir( oldpwd )
       end
     end
  end
end
