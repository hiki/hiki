# $Id: svn.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# You can distribute this under GPL.

#===== update_proc
add_update_proc {
  svn_commit if $repos_root
}

#===== delete_proc
add_delete_proc {
  svn_delete if $repos_root
}

#----- Subversion commit on updating
def svn_commit
  oldpwd = Dir.pwd
  begin
    Dir.chdir( "#{$data_path}/text" )
    system( "svn add -- #{@page.escape} > /dev/null 2>&1" )
    system( "svn ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1" )
  ensure
    Dir.chdir( oldpwd )
  end
end

#----- Subversion delete on deleting
def svn_delete
  oldpwd = Dir.pwd
  begin
    Dir.chdir( "#{$data_path}/text" )
    system( "svn remove -- #{@page.escape} > /dev/null 2>&1" )
    system( "svn ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1" )
  ensure
    Dir.chdir( oldpwd )
  end
end
