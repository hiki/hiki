# $Id: cvs.rb,v 1.11 2005-12-28 22:38:30 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require 'hiki/repos/default'

# CVS Repository Backend
module Hiki
  class HikifarmReposCvs < HikifarmReposBase
    def setup
      Dir.chdir( @data_root ) do
        system( "cvs -d #{@root} init > /dev/null 2>&1" )
        if not File.directory?(".CVSROOT")
          system( "cvs -d #{@root} co -d .CVSROOT CVSROOT > /dev/null 2>&1" )
        end
        Dir.chdir( ".CVSROOT" ) do
          system( "cvs -d #{@root} update > /dev/null 2>&1" )
        end
      end
    end

    def imported?( wiki )
      return File.directory?( "#{@root}/#{wiki}" )
    end

    def import( wiki )
      Dir.chdir( "#{@data_root}/#{wiki}/text" ) do
        system( "cvs -d #{@root} import -m 'Starting #{wiki} from #{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' #{wiki} hiki start > /dev/null 2>&1".untaint )
        Dir.chdir( '..' ) do
          system( "cvs -d #{@root} co -d text #{wiki} > /dev/null 2>&1" )
        end
      end
    end

    def update( wiki )
      Dir.chdir( "#{@data_root}/#{wiki}/text" ) do
        system( "cvs -d #{@root} update > /dev/null 2>&1" )
      end
    end
  end

  class ReposCvs < ReposBase
    def commit(page, msg = default_msg)
      Dir.chdir( "#{@data_path}/text" ) do
        system( "cvs -d #{@root} add -- #{page.escape} > /dev/null 2>&1".untaint )
        system( "cvs -d #{@root} ci -m '#{msg}' > /dev/null 2>&1".untaint )
      end
    end

    def delete(page, msg = default_msg)
      Dir.chdir( "#{@data_path}/text" ) do
        system( "cvs -d #{@root} remove -- #{page.escape} > /dev/null 2>&1".untaint )
        system( "cvs -d #{@root} ci -m '#{msg}' > /dev/null 2>&1".untaint )
      end
    end

    def get_revision(page, revision)
      ret = ''
      Dir.chdir("#{@data_path}/text") do
        open("|cvs -Q up -p -r 1.#{revision.to_i} #{page.escape.untaint}") do |f|
          ret = f.read
        end
      end
      ret
    end

    def revisions(page)
      require 'time'
      log = ''
      revs = []
      Dir.chdir("#{@data_path}/text") do
        open("|cvs -Q log #{page.escape.untaint}") do |f|
          log = f.read
        end
      end
      log.split(/----------------------------/).each do |tmp|
        if /revision 1.(\d+?)\ndate: (.*?);  author: (?:.*?);  state: (?:.*?);(.*?)?(?:;.*?)?\n(.*)/m =~ tmp then
          revs << [$1.to_i, Time.parse("#{$2}Z").localtime.to_s, $3, $4.chomp]
        end
      end
      revs
    end
  end
end
