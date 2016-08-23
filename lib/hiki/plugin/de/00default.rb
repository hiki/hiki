#
# labels
#
#
# preferences (resources)
#
add_conf_proc("default", "Standard-Einstellungen") do
  saveconf_default
  <<-HTML
      <h3 class="subtitle">Wiki Name</h3>
      <p>Der Name des Wikis. Er erscheint in de Seitentiteln.</p>
      <p><input name="site_name" value="#{h(@conf.site_name)}" size="40"></p>
      <h3 class="subtitle">Author</h3>
      <p>Ihr Name</p>
      <p><input name="author_name" value="#{h(@conf.author_name)}" size="40"></p>
      <h3 class="subtitle">Email Addresse</h3>
      <p>Email</p>
      <p><textarea name="mail" rows="4" cols="50">#{h(@conf.mail.join("\n"))}</textarea></p>
      <h3 class="subtitle">Sende Emails bei &auml;nderungen?</h3>
      <p>Einstellung, ob Sie &uuml;ber &auml;nderungen an Seiten per Email informiert werden m&ouml;chten. Die Email wird zu der Adresse die Sie in den Standard-Einstellungen eingegeben haben gesendet. (Stellen Sie sicher, dass ein SMTP server in der hikiconf.rb angegeben ist.)</p>
      <p><select name="mail_on_update">
         <option value="true"#{@conf.mail_on_update ? ' selected' : ''}>Ja</option>
         <option value="false"#{@conf.mail_on_update ? '' : ' selected'}>Nein</option>
         </select></p>
  HTML
end

add_conf_proc("password", "Passwort") do
  '<h3 class="password">Passwort</h3>' +
    case saveconf_password
    when :password_change_success
      "<p>Das Administrator Passwort wurde erfolgreich ge&auml;ndert.</p>"
    when :password_change_failure
      "<p>Sie haben entweder ein falsches altes Passwort eingegeben oder Sie haben sich bei der Passwort-wiederholung verschrieben.</p>"
    when nil
      "<p>Administrator Passwort &auml;ndern.</p>"
    end +
    <<-HTML
        <p>Jetziges Passwort: <input type="password" name="old_password" size="40"></p>
        <p>Neues Passwort: <input type="password" name="password1" size="40"></p>
        <p>Neues Passwort (wiederholung): <input type="password" name="password2" size="40"></p>
    HTML
end

add_conf_proc("theme", "Aussehen") do
  saveconf_theme
  r = <<-HTML
      <h3 class="subtitle">Aussehen</h3>
      <p>Themes um das Aussehen der Seiten zu ver&auml;ndern.</p>
      <p><select name="theme">
  HTML
  @conf_theme_list.each do |theme|
    r << %Q|<option value="#{theme[0]}"#{if theme[0] == @conf.theme then " selected" end}>#{theme[1]}</option>|
  end
  r << <<-HTML
      </select></p>
      <h3 class="subtitle">Theme URL</h3>
      <p>Eine URL eines Themes. Wenn Sie hier eine URL angeben, wird dieses CSS Theme verwendet und das oben angegebene ignoriert.</p>
      <p><input name="theme_url" value="#{h(@conf.theme_url)}" size="60"></p>
      <h3 class="subtitle">Theme Ordner</h3>
      <p>Ordner der vorhandenen Themes.</p>
      <p><input name="theme_path" value="#{h(@conf.theme_path)}" size="60"></p>
      <h3 class="subtitle">Seitenleiste</h3>
      <p>Manche Themes k&ouml;nnen die Seitenleiste nicht ordnungsgem&auml;&szlig; darstellen. Wenn sie eines dieser Themes benutzten, den Wert auf 'Aus' setzen.</p>
      <p><select name="sidebar">
         <option value="true"#{@conf.use_sidebar ? ' selected' : ''}>An</option>
         <option value="false"#{@conf.use_sidebar ? '' : ' selected'}>Aus</option>
         </select></p>
      <h3 class="subtitle">CSS Klassename der die Haupt-Fl&auml;che</h3>
      <p>CSS Klassenname der die Haupt-Fl&auml;che (Stardard: 'main').</p>
      <p><input name="main_class" value="#{h(@conf.main_class)}" size="20"></p>
      <h3 class="subtitle">CSS Klassenname der Seitenleiste</h3>
      <p>CSS Klassenname der Seitenleiste (Standard: 'sidebar').</p>
      <p><input name="sidebar_class" value="#{h(@conf.sidebar_class)}" size="20"></p>
      <h3 class="subtitle">Auto link</h3>
      <p>Um die Auto link Funktion zu aktivieren, den Wert auf 'An' setzen.</p>
      <p><select name="auto_link">
         <option value="true"#{@conf.auto_link ? ' selected' : ''}>An</option>
         <option value="false"#{@conf.auto_link ? '' : ' selected'}>Aus</option>
         </select></p>
      <h3 class="subtitle">WikiNamen</h3>
      <p>Wenn sie WikiNamen deaktivieren wollen, den Wert auf 'Aus' setzen.</p>
      <p><select name="use_wikiname">
         <option value="true"#{@conf.use_wikiname ? ' selected' : ''}>An</option>
         <option value="false"#{@conf.use_wikiname ? '' : ' selected'}>Aus</option>
         </select></p>
  HTML
end

add_conf_proc("xmlrpc", "XML-RPC") do
  saveconf_xmlrpc

  <<-HTML
      <h3 class="subtitle">XML-RPC</h3>
      <p>Um die XML-RPC interfaces zu deaktivieren, den Wert auf 'Aus' setzen.</p>
      <p><select name="xmlrpc_enabled">
         <option value="true"#{@conf.xmlrpc_enabled ? ' selected' : ''}>An</option>
         <option value="false"#{@conf.xmlrpc_enabled ? '' : ' selected'}>Aus</option>
         </select></p>
  HTML
end
