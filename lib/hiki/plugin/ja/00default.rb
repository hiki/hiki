# -*- coding: utf-8 -*-
#
# preferences (resources)
#
add_conf_proc("default", "基本") do
  saveconf_default
  <<-HTML
      <h3 class="subtitle">サイト名</h3>
      <p>サイト名を指定します。</p>
      <p><input name="site_name" value="#{h(@conf.site_name)}" size="40"></p>
      <h3 class="subtitle">著者名</h3>
      <p>あなたの名前を指定します。</p>
      <p><input name="author_name" value="#{h(@conf.author_name)}" size="40"></p>
      <h3 class="subtitle">メールアドレス</h3>
      <p>あなたのメールアドレスを指定します。1行に1アドレスずつ指定します。</p>
      <p><textarea name="mail" rows="4" cols="50">#{h(@conf.mail.join("\n"))}</textarea></p>
      <h3 class="subtitle">更新をメールで通知</h3>
      <p>ページの更新があった場合にメールで通知するかどうかを指定します。メールは基本設定で指定したアドレスに送信されます。あらかじめhikiconf.rbでSMTPサーバを設定しておいてください。</p>
      <p><select name="mail_on_update">
         <option value="true"#{@conf.mail_on_update ? ' selected' : ''}>メール で通知</option>
         <option value="false"#{@conf.mail_on_update ? '' : ' selected'}>非通知</option>
         </select></p>
  HTML
end

add_conf_proc("password", "パスワード") do
  '<h3 class="password">パスワード</h3>' +
    case saveconf_password
    when :password_change_success
      "<p>管理者用パスワードを変更しました。</p>"
    when :password_change_failure
      "<p>管理者用パスワードが間違っているか、パスワードが一致しません。</p>"
    when nil
      "<p>管理者用パスワードを変更します。</p>"
    end +
    <<-HTML
        <p>現在のパスワード: <input type="password" name="old_password" size="40"></p>
        <p>新しいパスワード: <input type="password" name="password1" size="40"></p>
        <p>新しいパスワード（確認用に再入力してください）: <input type="password" name="password2" size="40"></p>
    HTML
end

add_conf_proc("theme", "表示設定") do
  saveconf_theme
  r = <<-HTML
      <h3 class="subtitle">テーマの指定</h3>
      <p>表示に使用するテーマを選択することができます。</p>
      <p><select name="theme">
  HTML
  @conf_theme_list.each do |theme|
    r << %Q|<option value="#{theme[0]}"#{if theme[0] == @conf.theme then " selected" end}>#{theme[1]}</option>|
  end
  r << <<-HTML
      </select></p>
      <h3 class="subtitle">テーマURLの指定</h3>
      <p>テーマがあるURLを指定することができます。直接CSSを指定した場合、上の「テーマの指定」で選択したテーマは無視され、指定したCSSが使われます。</p>
      <p><input name="theme_url" value="#{h(@conf.theme_url)}" size="60"></p>
      <h3 class="subtitle">テーマディレクトリの指定</h3>
      <p>テーマがあるディレクトリを指定することができます。（複数設置時に使用）</p>
      <p><input name="theme_path" value="#{h(@conf.theme_path)}" size="60"></p>
      <h3 class="subtitle">サイドバーの利用</h3>
      <p>テーマによってはサイドバーを利用すると表示が乱れるものがあります。その場合、サイドバーの表示をオフにすることができます。</p>
      <p><select name="sidebar">
         <option value="true"#{@conf.use_sidebar ? ' selected' : ''}>使用する</option>
         <option value="false"#{@conf.use_sidebar ? '' : ' selected'}>使用しない</option>
         </select></p>
      <h3 class="subtitle">メインエリアのクラス名(CSS)の指定</h3>
      <p>デフォルトでは本文部分のクラス名として'main'を使用しますが、それ以外のクラス名を使用したい場合に指定します。</p>
      <p><input name="main_class" value="#{h(@conf.main_class)}" size="20"></p>
      <h3 class="subtitle">サイドバーのクラス名(CSS)の指定</h3>
      <p>デフォルトではサイドバーのクラス名として'sidebar'を使用しますが、それ以外のクラス名を使用したい場合に指定します。</p>
      <p><input name="sidebar_class" value="#{h(@conf.sidebar_class)}" size="20"></p>
      <h3 class="subtitle">オートリンクの利用</h3>
      <p>既存のページに自動的にリンクを設定するオートリンク機能を使用するかどうか指定します。</p>
      <p><select name="auto_link">
         <option value="true"#{@conf.auto_link ? ' selected' : ''}>使用する</option>
         <option value="false"#{@conf.auto_link ? '' : ' selected'}>使用しない</option>
         </select></p>
      <h3 class="subtitle">WikiName によるリンク機能の利用</h3>
      <p>WikiName によるリンク機能を使用するかどうか指定します。</p>
      <p><select name="use_wikiname">
         <option value="true"#{@conf.use_wikiname ? ' selected' : ''}>使用する</option>
         <option value="false"#{@conf.use_wikiname ? '' : ' selected'}>使用しない</option>
         </select></p>
  HTML
end

add_conf_proc("xmlrpc", "XML-RPC") do
  saveconf_xmlrpc

  <<-HTML
      <h3 class="subtitle">XML-RPC</h3>
      <p>XML-RPC インタフェイスを有効にするかどうかを指定します。</p>
      <p><select name="xmlrpc_enabled">
         <option value="true"#{@conf.xmlrpc_enabled ? ' selected' : ''}>有効</option>
         <option value="false"#{@conf.xmlrpc_enabled ? '' : ' selected'}>無効</option>
         </select></p>
  HTML
end

