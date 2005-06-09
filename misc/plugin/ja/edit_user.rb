# $Id: edit_user.rb,v 1.2 2005-06-09 08:12:39 fdiary Exp $
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def label_edit_user_config; 'ユーザ編集'; end
def label_edit_user_title; 'ユーザの削除 / パスワードの変更'; end
def label_edit_user_add_title; 'ユーザの追加'; end
def label_edit_user_description
  '一行ずつ「ユーザ名&nbsp;パスワード」という書式で書いてください。'
end
def label_edit_user_auth_title; '編集の制限'; end
def label_edit_user_auth_description
  '登録ユーザのみ編集できるように制限しますか？'
end
def label_edit_user_auth_candidate
  [ 'はい', 'いいえ' ]
end
def label_edit_user_delete; '削除'; end
def label_edit_user_name; 'ユーザ名'; end
def label_edit_user_new_password; '新パスワード'; end
