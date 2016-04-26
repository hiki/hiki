#
# labels
#
#
# preferences (resources)
#
add_conf_proc("default", "Basic preferences") do
  saveconf_default
  <<-HTML
      <h3 class="subtitle">Site name</h3>
      <p>Enter the name of your site.  This will appear in page titles.</p>
      <p><input name="site_name" value="#{h(@conf.site_name)}" size="40"></p>
      <h3 class="subtitle">Author</h3>
      <p>Enter your name.</p>
      <p><input name="author_name" value="#{h(@conf.author_name)}" size="40"></p>
      <h3 class="subtitle">E-mail address</h3>
      <p>Enter your e-mail address. (One address in one line)</p>
      <p><textarea name="mail" rows="4" cols="50">#{h(@conf.mail.join("\n"))}</textarea></p>
      <h3 class="subtitle">Send update e-mails?</h3>
      <p>Set whether or not you want to have e-mail sent when a page is updated.  E-mail will be sent to the address set in the Basic Preferences.  (Make sure to specify an SMTP server beforehand in hikiconf.rb.)</p>
      <p><select name="mail_on_update">
         <option value="true"#{@conf.mail_on_update ? ' selected' : ''}>Yes</option>
         <option value="false"#{@conf.mail_on_update ? '' : ' selected'}>No</option>
         </select></p>
  HTML
end

add_conf_proc("password", "Password") do
  '<h3 class="password">Password</h3>' +
    case saveconf_password
    when :password_change_success
      "<p>The admin password has been changed successfully.</p>"
    when :password_change_failure
      "<p>The old password is wrong or new passwords are not same.</p>"
    when nil
      "<p>You can change the admin password.</p>"
    end +
    <<-HTML
        <p>Current password: <input type="password" name="old_password" size="40"></p>
        <p>New password: <input type="password" name="password1" size="40"></p>
        <p>New password (confirm): <input type="password" name="password2" size="40"></p>
    HTML
end

add_conf_proc("theme", "Appearance") do
  saveconf_theme
  r = <<-HTML
      <h3 class="subtitle">Theme</h3>
      <p>Select a theme to use in displaying pages.
      <p><select name="theme">
  HTML
  @conf_theme_list.each do |theme|
    r << %Q|<option value="#{theme[0]}"#{if theme[0] == @conf.theme then " selected" end}>#{theme[1]}</option>|
  end
  r << <<-HTML
      </select></p>
      <h3 class="subtitle">Theme URL</h3>
      <p>Specify a URL where a theme is located.  If you specify a CSS URL, the theme selected above will be ignored, and the CSS will be used.</p>
      <p><input name="theme_url" value="#{h(@conf.theme_url)}" size="60"></p>
      <h3 class="subtitle">Theme directory</h3>
      <p>Enter the directory where themes are located.</p>
      <p><input name="theme_path" value="#{h(@conf.theme_path)}" size="60"></p>
      <h3 class="subtitle">Sidebar</h3>
      <p>Some themes cannot properly display the sidebar.  If you are using one of these themes, set this value to off.</p>
      <p><select name="sidebar">
         <option value="true"#{@conf.use_sidebar ? ' selected' : ''}>On</option>
         <option value="false"#{@conf.use_sidebar ? '' : ' selected'}>Off</option>
         </select></p>
      <h3 class="subtitle">CSS class name for the main area</h3>
      <p>Enter the CSS class name for the main area (default: 'main').</p>
      <p><input name="main_class" value="#{h(@conf.main_class)}" size="20"></p>
      <h3 class="subtitle">CSS class name for the sidebar</h3>
      <p>Enter the CSS class name for the sidebar (default: 'sidebar').</p>
      <p><input name="sidebar_class" value="#{h(@conf.sidebar_class)}" size="20"></p>
      <h3 class="subtitle">Auto link</h3>
      <p>If you want to use the auto link function, set this value to on.</p>
      <p><select name="auto_link">
         <option value="true"#{@conf.auto_link ? ' selected' : ''}>On</option>
         <option value="false"#{@conf.auto_link ? '' : ' selected'}>Off</option>
         </select></p>
      <h3 class="subtitle">WikiName</h3>
      <p>If you want to disable WikiName, set this value to off.</p>
      <p><select name="use_wikiname">
         <option value="true"#{@conf.use_wikiname ? ' selected' : ''}>On</option>
         <option value="false"#{@conf.use_wikiname ? '' : ' selected'}>Off</option>
         </select></p>
  HTML
end

add_conf_proc("xmlrpc", "XML-RPC") do
  saveconf_xmlrpc

  <<-HTML
      <h3 class="subtitle">XML-RPC</h3>
      <p>If you want to disable XML-RPC interfaces, set this value to off.</p>
      <p><select name="xmlrpc_enabled">
         <option value="true"#{@conf.xmlrpc_enabled ? ' selected' : ''}>On</option>
         <option value="false"#{@conf.xmlrpc_enabled ? '' : ' selected'}>Off</option>
         </select></p>
  HTML
end
