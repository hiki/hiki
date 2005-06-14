# $Id: edit_user.rb,v 1.3 2005-06-14 13:49:07 fdiary Exp $
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def label_edit_user_config; 'Edit users'; end
def label_edit_user_title; 'Delete users / Change passwords'; end
def label_edit_user_add_title; 'Add users'; end
def label_edit_user_description
  'Each line has one user, which is in the form of "name&nbsp;password".'
end
def label_edit_user_auth_title; 'Restrict editing'; end
def label_edit_user_auth_description
  'Do you permit only registrated users to edit?'
end
def label_edit_user_auth_candidate
  [ 'Yes', 'No' ]
end
def label_edit_user_delete; 'Delete'; end
def label_edit_user_name; 'Name'; end
def label_edit_user_new_password; 'New password'; end

