# $Id: cvs.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2003, Kazuhiko <kazuhiko@fdiary.net>
# You can distribute this under GPL.

#===== update_proc
add_update_proc {
  cvs_commit if $repos_root
}

#===== delete_proc
add_delete_proc {
  cvs_delete if $repos_root
}

#----- cvs commit on updating
def cvs_commit
  oldpwd = Dir.pwd
  begin
    Dir.chdir( "#{$data_path}/text" )
    system( "cvs -d #{$repos_root} add -- #{@page.escape} > /dev/null 2>&1" )
    system( "cvs -d #{$repos_root} ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1" )
  ensure
    Dir.chdir( oldpwd )
  end
end

#----- cvs delete on deleting
def cvs_delete
  oldpwd = Dir.pwd
  begin
    Dir.chdir( "#{$data_path}/text" )
    system( "cvs -d #{$repos_root} remove -- #{@page.escape} > /dev/null 2>&1" )
    system( "cvs -d #{$repos_root} ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1" )
  ensure
    Dir.chdir( oldpwd )
  end
end
