# $Id: cvs.rb,v 1.4 2004-06-26 14:12:29 fdiary Exp $
# Copyright (C) 2003, Kazuhiko <kazuhiko@fdiary.net>
# You can distribute this under GPL.

#===== update_proc
add_update_proc {
  cvs_commit if @conf.repos_root
}

#===== delete_proc
add_delete_proc {
  cvs_delete if @conf.repos_root
}

#----- cvs commit on updating
def cvs_commit
  oldpwd = Dir.pwd.untaint
  begin
    Dir.chdir( "#{@conf.data_path}/text" )
    system( "cvs -d #{@conf.repos_root} add -- #{@page.escape} > /dev/null 2>&1".untaint )
    system( "cvs -d #{@conf.repos_root} ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint )
  ensure
    Dir.chdir( oldpwd )
  end
end

#----- cvs delete on deleting
def cvs_delete
  oldpwd = Dir.pwd.untaint
  begin
    Dir.chdir( "#{@conf.data_path}/text" )
    system( "cvs -d #{@conf.repos_root} remove -- #{@page.escape} > /dev/null 2>&1".untaint )
    system( "cvs -d #{@conf.repos_root} ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint )
  ensure
    Dir.chdir( oldpwd )
  end
end
