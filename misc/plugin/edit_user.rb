# $Id: edit_user.rb,v 1.1 2005-06-08 08:36:09 fdiary Exp $
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def saveconf_edit_user
  if @mode == 'saveconf' then
    @conf['user.auth'] = @cgi.params['user.auth'][0].to_i
    @conf['user.list'] = []
    @cgi.params['user.list'][0].each do |line|
      if /^([^\s]+)\s+([^\s]+)/ =~ line
	@conf['user.list'] << [$1, $2] unless @conf['user.list'].find{|i,j| $2 == j}
      end
    end
  end
  @conf['user.auth'] ||= 1
end

add_conf_proc('user', label_edit_user_config) do
  saveconf_edit_user
  str = <<-HTML
  <h3 class="subtitle">#{label_edit_user_title}</h3>
  <p>#{label_edit_user_description}</p>
  <p><textarea name="user.list" cols="40" rows="10">#{(@conf['user.list'] || []).collect{|i, j| "#{i} #{j}"}.join("\n")}</textarea></p>
  <h3 class="subtitle">#{label_edit_user_auth_title}</h3>
  <p>#{label_edit_user_auth_description}</p>
  <p><select name="edit.auth">
  HTML
  label_edit_user_auth_candidate.each_index{ |i|
    str << %Q|<option value="#{i}"#{@conf['user.auth'] == i ? ' selected' : ''}>#{label_edit_user_auth_candidate[i]}</option>\n|
  }
  str << "</select></p>\n"
  str
end

def auth?
  return false if @conf['user.auth'] == 0 && !@user
  return true
end
