# -*- coding: utf-8 -*-
#
# preferences (resources)
#
add_conf_proc("default", "Préférences de base") do
  saveconf_default
  <<-HTML
      <h3 class="subtitle">Pseudonyme</h3>
      <p>Entrez votre nom d'utilisateur.  Il apparaîtra comme élément de titre.</p>
      <p><input name="site_name" value="#{h(@conf.site_name)}" size="40"></p>
      <h3 class="subtitle">Auteur</h3>
      <p>Entrez votre nom complet.</p>
      <p><input name="author_name" value="#{h(@conf.author_name)}" size="40"></p>
      <h3 class="subtitle">Adresse électronique</h3>
      <p>Entrez votre adresse e-mail.</p>
      <p><textarea name="mail" rows="4" cols="50">#{h(@conf.mail.join("\n"))}</textarea></p>
      <h3 class="subtitle">Notification par e-mail.</h3>
      <p>Si cette option est activée, un e-mail de notification sera envoyé à votre adresse électronique via le serveur SMTP (définit dans hikiconf.rb) lorsqu'une page est modifiée.  Aucun e-mail ne sera envoyé si cette option est désactivée.</p>
      <p><select name="mail_on_update">
         <option value="true"#{@conf.mail_on_update ? ' selected' : ''}>ON</option>
         <option value="false"#{@conf.mail_on_update ? '' : ' selected'}>OFF</option>
         </select></p>
  HTML
end

add_conf_proc("password", "Mot de passe") do
  '<h3 class="password">Mot de passe</h3>' +
    case saveconf_password
    when :password_change_success
      "<p>The admin password has been changed successfully.</p>"
    when :password_change_failure
      "<p>Sorry, wrong password.</p>"
    when nil
      "<p>You can change the admin password.</p>"
    end +
    <<-HTML
      <p>Mot de passe courant: <input type="password" name="old_password" size="40"></p>
      <p>Nouveau mot de passe: <input type="password" name="password1" size="40"></p>
      <p>Nouveau mot de passe (confirmez): <input type="password" name="password2" size="40"></p>
    HTML
end

add_conf_proc("theme", "Apparence") do
  saveconf_theme
  r = <<-HTML
      <h3 class="subtitle">Thème</h3>
      <p>Selectionnez un thème.</p>
      <p><select name="theme">
  HTML
  @conf_theme_list.each do |theme|
    r << %Q|<option value="#{theme[0]}"#{if theme[0] == @conf.theme then " selected" end}>#{theme[1]}</option>|
  end
  r << <<-HTML
      </select></p>
      <h3 class="subtitle">Thème - URL</h3>
      <p>Entrez l'URL d'un thème.</p>
      <p><input name="theme_url" value="#{h(@conf.theme_url)}" size="60"></p>
      <h3 class="subtitle">Thème - Répertoire</h3>
      <p>Entrez le répertoire du thème.</p>
      <p><input name="theme_path" value="#{h(@conf.theme_path)}" size="60"></p>
      <h3 class="subtitle">Barre contextuelle</h3>
      <p>ON et la barre contextuelle sera affichée.  Si vous voulez utiliser un thème qui ne gère pas de barre contextuelle, vous devez sélectionner OFF.</p>
      <p><select name="sidebar">
         <option value="true"#{@conf.use_sidebar ? ' selected' : ''}>ON</option>
         <option value="false"#{@conf.use_sidebar ? '' : ' selected'}>OFF</option>
         </select></p>
      <h3 class="subtitle">Nom de la classe dans la section principale (CSS)</h3>
      <p>Entrez le nom CSS de la classe dans la section principale.</p>
      <p><input name="main_class" value="#{h(@conf.main_class)}" size="20"></p>
      <h3 class="subtitle">Nom de la classe dans la barre contextuelle (CSS)</h3>
      <p>Entrez le nom CSS de la classe dans la barre contextuelle.</p>
      <p><input name="sidebar_class" value="#{h(@conf.sidebar_class)}" size="20"></p>
      <h3 class="subtitle">Liens automatiques</h3>
      <p>Choisissez ON si vous désirez activer les liens automatiques.</p>
      <p><select name="auto_link">
         <option value="true"#{@conf.auto_link ? ' selected' : ''}>ON</option>
         <option value="false"#{@conf.auto_link ? '' : ' selected'}>OFF</option>
         </select></p>
      <h3 class="subtitle">WikiName</h3>
      <p>(TRANSLATE PLEASE) If you want to disable WikiName, set this value to off.</p>
      <p><select name="use_wikiname">
         <option value="true"#{@conf.use_wikiname ? ' selected' : ''}>ON</option>
         <option value="false"#{@conf.use_wikiname ? '' : ' selected'}>OFF</option>
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
