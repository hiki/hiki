# $Id: edit_user.rb,v 1.1 2005-06-08 08:36:09 fdiary Exp $
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def label_edit_user_config; 'ユーザ編集'; end
def label_edit_user_title; 'ユーザリストの編集'; end
def label_edit_user_description
  '一行ずつ「ユーザ名&nbsp;パスワード」という書式で書いてください。パスワードのみでユーザを識別するため、同じパスワードは使えません。また、管理者用パスワードとも一致しないようにしてください。'
end
def label_edit_user_auth_title; '編集の制限'; end
def label_edit_user_auth_description
  '登録ユーザのみ編集できるように制限しますか？'
end
def label_edit_user_auth_candidate
  [ 'はい', 'いいえ' ]
end
