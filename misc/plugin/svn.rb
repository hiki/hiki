# $Id: svn.rb,v 1.4 2004-04-07 06:39:56 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
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
  oldpwd = Dir.pwd.untaint
  begin
    Dir.chdir( "#{$data_path}/text" )
    system( "svn add -- #{@page.escape} > /dev/null 2>&1".untaint )
    system( "svn propdel svn:mime-type -- #{@page.escape} > /dev/null 2>&1".untaint )
    system( "svn ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint )
  ensure
    Dir.chdir( oldpwd )
  end
end

#----- Subversion delete on deleting
def svn_delete
  oldpwd = Dir.pwd.untaint
  begin
    Dir.chdir( "#{$data_path}/text" )
    system( "svn remove -- #{@page.escape} > /dev/null 2>&1".untaint )
    system( "svn ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint )
  ensure
    Dir.chdir( oldpwd )
  end
end
