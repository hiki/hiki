# $Id: auth_typekey.rb,v 1.1 2005-03-06 09:05:23 fdiary Exp $
# Copyright (C) 2005 TAKEUCHI Hitoshi

def label_auth_typekey_login
<<EOS
<div class="hello">
  ページを編集するには<a href="#{login_url}">ログイン</a>が必要です。
</div>
EOS
end

def label_auth_typekey_hello
  'こんにちは。%sさん'
end

def label_auth_typekey_config
  'TypeKey認証'
end

def label_auth_typekey_token
  'TypeKeyトークン'
end

def label_auth_typekey_token_msg
  'TypeKeyのトークンを指定します。トークンはTypeKeyのサイトのアカウント情報で確認してください。'
end
