#
# preferences (resources)
#
add_conf_proc( 'default', '基本' ) do
  saveconf_default
  <<-HTML
      <h3 class="subtitle">サイト名</h3>
      <p>サイト名を指定します。</p>
      <p><input name="site_name" value="#{CGI::escapeHTML(@conf.site_name)}" size="40"></p>
      <h3 class="subtitle">著者名</h3>
      <p>あなたの名前を指定します。</p>
      <p><input name="author_name" value="#{CGI::escapeHTML(@conf.author_name)}" size="40"></p>
      <h3 class="subtitle">メールアドレス</h3>
      <p>あなたのメールアドレスを指定します。</p>
      <p><input name="mail" value="#{CGI::escapeHTML(@conf.mail)}" size="40"></p>
      <h3 class="subtitle">更新をメールで通知</h3>
      <p>ページの更新があった場合にメールで通知するかどうかを指定します。メールは基本設定で指定したアドレスに送信されます。あらかじめconfig.rbでSMTPサーバを設定しておいてください。</p>
      <p><select name="mail_on_update">
         <option value="true">メールで通知</option>
         <option value="false">非通知</option>
         </select></p>
  HTML
end

add_conf_proc( 'password', 'パスワード' ) do
  saveconf_password
  <<-HTML
      <h3 class="password">パスワード</h3>
      <p>管理者用パスワードを変更したい場合のみ入力してください。</p>
      <p>現在のパスワード: <input type="password" name="old_password" size="40"></p>
      <p>新しいパスワード: <input type="password" name="password1" size="40"></p>
      <p>新しいパスワード（確認用に再入力してください）: <input type="password" name="password2" size="40"></p>
  HTML
end

add_conf_proc( 'theme', '表示設定' ) do
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
      <p><input name="theme_url" value="#{CGI::escapeHTML(@conf.theme_url)}" size="60"></p>
      <h3 class="subtitle">テーマディレクトリの指定</h3>
      <p>テーマがあるディレクトリを指定することができます。（複数設置時に使用）</p>
      <p><input name="theme_path" value="#{CGI::escapeHTML(@conf.theme_path)}" size="60"></p>
      <h3 class="subtitle">サイドバーの利用</h3>
      <p>テーマによってはサイドバーを利用すると表示が乱れるものがあります。その場合、サイドバーの表示をオフにすることができます。</p>
      <p><select name="sidebar">
         <option value="true">使用する</option>
         <option value="false">使用しない</option>
         </select></p>
      <h3 class="subtitle">メインエリアのクラス名(CSS)の指定</h3>
      <p>デフォルトでは本文部分のクラス名として'main'を使用しますが、それ以外のクラス名を使用したい場合に指定します。</p>
      <p><input name="main_class" value="#{CGI::escapeHTML(@conf.main_class)}" size="20"></p>
      <h3 class="subtitle">サイドバーのクラス名(CSS)の指定</h3>
      <p>デフォルトではサイドバーのクラス名として'sidebar'を使用しますが、それ以外のクラス名を使用したい場合に指定します。</p>
      <p><input name="sidebar_class" value="#{CGI::escapeHTML(@conf.sidebar_class)}" size="20"></p>
      <h3 class="subtitle">オートリンクの利用</h3>
      <p>既存のページに自動的にリンクを設定するオートリンク機能を使用するかどうか指定します。</p>
      <p><select name="auto_link">
         <option value="true">使用する</option>
         <option value="false">使用しない</option>
         </select></p>
  HTML
end
