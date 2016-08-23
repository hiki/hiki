# -*- coding: utf-8 -*-
#
# preferences (resources)
#
add_conf_proc("default", "Preferenze base") do
  saveconf_default
  <<-HTML
      <h3 class="subtitle">Nome del sito</h3>
      <p>Imposta il nome del sito. Questo appare come titolo dell'elemento.</p>
      <p><input name="site_name" value="#{h(@conf.site_name)}" size="40"></p>
      <h3 class="subtitle">Autore</h3>
      <p>Set your name.</p>
      <p><input name="author_name" value="#{h(@conf.author_name)}" size="40"></p>
      <h3 class="subtitle">Indirizzo email</h3>
      <p>Imposta il tuo indirizzo email.</p>
      <p><textarea name="mail" rows="4" cols="50">#{h(@conf.mail.join("\n"))}</textarea></p>
      <h3 class="subtitle">Manda email per le modifiche.</h3>
      <p>Se è ABILITATO, l'email di notifica è inviata all'"Indirizzo email" delle preferenze di base via SMTP server(che è impostato in hikiconf.rb) quando una pagina è aggiornata. Se è DISABILITATO, l'email viene inviata.</p>
      <p><select name="mail_on_update">
         <option value="true"#{@conf.mail_on_update ? ' selected' : ''}>ABILIATO</option>
         <option value="false"#{@conf.mail_on_update ? '' : ' selected'}>DISABILIATO</option>
         </select></p>
  HTML
end

add_conf_proc("password", "Password") do
  '<h3 class="password">Password</h3>' +
    case saveconf_password
    when :password_change_success
      "<p>The admin password has been changed successfully.</p>"
    when :password_change_failure
      "<p>Sorry, wrong password.</p>"
    when nil
      "<p>You can change the admin password.</p>"
    end +
    <<-HTML
        <p>Password corrente: <input type="password" name="old_password" size="40"></p>
        <p>Password nuova: <input type="password" name="password1" size="40"></p>
        <p>Password nuova(conferma): <input type="password" name="password2" size="40"></p>
    HTML
end

add_conf_proc("theme", "Aspetto") do
  saveconf_theme
  r = <<-HTML
      <h3 class="subtitle">Tema</h3>
      <p>Scegli un tema.</p>
      <p><select name="theme">
  HTML
  @conf_theme_list.each do |theme|
    r << %Q|<option value="#{theme[0]}"#{if theme[0] == @conf.theme then " selected" end}>#{theme[1]}</option>|
  end
  r << <<-HTML
      </select></p>
      <h3 class="subtitle">URL Tema</h3>
      <p>Imposta URL tema.</p>
      <p><input name="theme_url" value="#{h(@conf.theme_url)}" size="60"></p>
      <h3 class="subtitle">Cartella tema</h3>
      <p>Imposta cartella tema.</p>
      <p><input name="theme_path" value="#{h(@conf.theme_path)}" size="60"></p>
      <h3 class="subtitle">Barra laterale</h3>
      <p>ABILITATO se la barra laterale è mostrata. Se vuoi usare un tema che non supporta la barra laterale, devi selezionare DISABILITATO qui.</p>
      <p><select name="sidebar">
         <option value="true"#{@conf.use_sidebar ? ' selected' : ''}>ABILIATO</option>
         <option value="false"#{@conf.use_sidebar ? '' : ' selected'}>DISABILIATO</option>
         </select></p>
      <h3 class="subtitle">Nome della classe nell'area principale(CSS)</h3>
      <p>Imposta il nome della classe CSS nell'area principale.</p>
      <p><input name="main_class" value="#{h(@conf.main_class)}" size="20"></p>
      <h3 class="subtitle">Nome del CSS nella barra laterale (CSS)</h3>
      <p>Imposta il nome della classe CSS nella barra laterale.</p>
      <p><input name="sidebar_class" value="#{h(@conf.sidebar_class)}" size="20"></p>
      <h3 class="subtitle">Collegamento automatico</h3>
      <p>Imposta ABILITATO se vuoi usare il collegamento automatico.</p>
      <p><select name="auto_link">
         <option value="true"#{@conf.auto_link ? ' selected' : ''}>ABILIATO</option>
         <option value="false"#{@conf.auto_link ? '' : ' selected'}>DISABILIATO</option>
         </select></p>
      <h3 class="subtitle">WikiName</h3>
      <p>(TRANSLATE PLEASE) If you want to disable WikiName, set this value to off.</p>
      <p><select name="use_wikiname">
         <option value="true"#{@conf.use_wikiname ? ' selected' : ''}>ABILIATO</option>
         <option value="false"#{@conf.use_wikiname ? '' : ' selected'}>DISABILIATO</option>
         </select></p>
  HTML
end

add_conf_proc("xmlrpc", "XML-RPC") do
  saveconf_xmlrpc

  <<-HTML
      <h3 class="subtitle">XML-RPC</h3>
      <p>(TRANSLATE PLEASE) If you want to disable XML-RPC interfaces, set this value to off.</p>
      <p><select name="xmlrpc_enabled">
         <option value="true"#{@conf.xmlrpc_enabled ? ' selected' : ''}>On</option>
         <option value="false"#{@conf.xmlrpc_enabled ? '' : ' selected'}>Off</option>
         </select></p>
  HTML
end
