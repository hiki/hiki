#
# labels
#
#
# preferences (resources)
#
add_conf_proc( 'default', 'Basic preferences' ) do
  saveconf_default
  <<-HTML
      <h3 class="subtitle">Site names</h3>
      <p>Set your site name. This appeared as title element.</p>
      <p><input name="site_name" value="#{CGI::escapeHTML(@conf.site_name)}" size="40"></p>
      <h3 class="subtitle">Author</h3>
      <p>Set your name.</p>
      <p><input name="author_name" value="#{CGI::escapeHTML(@conf.author_name)}" size="40"></p>
      <h3 class="subtitle">E-Mail address</h3>
      <p>Set your e-mail address.</p>
      <p><input name="mail" value="#{CGI::escapeHTML(@conf.mail)}" size="40"></p>
      <h3 class="subtitle">Send mail for changes.</h3>
      <p>If ON, notice-mail is sended to "e-mail address" of Basic preferences via SMTP server(which set in config.rb) when a page is updated. If OFF, e-mail isn't sended.</p>
      <p><select name="mail_on_update">
         <option value="true"#{@conf.mail_on_update ? ' selected' : ''}>ON</option>
         <option value="false"#{@conf.mail_on_update ? '' : ' selected'}>OFF</option>
         </select></p>
  HTML
end

add_conf_proc( 'password', 'Password' ) do
  saveconf_password
  <<-HTML
      <h3 class="password">Password</h3>
      <p>Input passwords below when you want to change the password only.</p>
      <p>Current password: <input type="password" name="old_password" size="40"></p>
      <p>New password: <input type="password" name="password1" size="40"></p>
      <p>New password(confirm): <input type="password" name="password2" size="40"></p>
  HTML
end

add_conf_proc( 'theme', 'Appearance' ) do
  saveconf_theme
  r = <<-HTML
      <h3 class="subtitle">Theme</h3>
      <p>Select a theme.
      <p><select name="theme">
  HTML
  @conf_theme_list.each do |theme|
    r << %Q|<option value="#{theme[0]}"#{if theme[0] == @conf.theme then " selected" end}>#{theme[1]}</option>|
  end
  r << <<-HTML
      </select></p>
      <h3 class="subtitle">Theme URL</h3>
      <p>Enter the URL of a theme.</p>
      <p><input name="theme_url" value="#{CGI::escapeHTML(@conf.theme_url)}" size="60"></p>
      <h3 class="subtitle">Theme directory</h3>
      <p>Enter the directory of themes.</p>
      <p><input name="theme_path" value="#{CGI::escapeHTML(@conf.theme_path)}" size="60"></p>
      <h3 class="subtitle">Sidebar</h3>
      <p>ON if Sidebar is shown. If you want to use a theme which doesn't support Sidebar, you need to select OFF here.</p>
      <p><select name="sidebar">
         <option value="true"#{@conf.use_sidebar ? ' selected' : ''}>ON</option>
         <option value="false"#{@conf.use_sidebar ? '' : ' selected'}>OFF</option>
         </select></p>
      <h3 class="subtitle">Class name of the main area (CSS)</h3>
      <p>Enter the class name of the main area (default: 'main').</p>
      <p><input name="main_class" value="#{CGI::escapeHTML(@conf.main_class)}" size="20"></p>
      <h3 class="subtitle">Class name of the side bar (CSS)</h3>
      <p>Enter the class name of the side bar (default: 'sidebar').</p>
      <p><input name="sidebar_class" value="#{CGI::escapeHTML(@conf.sidebar_class)}" size="20"></p>
      <h3 class="subtitle">Auto link</h3>
      <p>If you want to use the auto link function, select 'On' here.</p>
      <p><select name="auto_link">
         <option value="true"#{@conf.auto_link ? ' selected' : ''}>ON</option>
         <option value="false"#{@conf.auto_link ? '' : ' selected'}>OFF</option>
         </select></p>
  HTML
end
