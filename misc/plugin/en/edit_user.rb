# $Id: edit_user.rb,v 1.1 2005-06-08 08:36:09 fdiary Exp $
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def label_edit_user_config; 'Edit users'; end
def label_edit_user_title; 'Edit a user list'; end
def label_edit_user_description
  'Each line has one user, which is in the form of "name&nbsp;password". Since a user will by authenticated by a password only, all passwords should be unique.'
end
def label_edit_user_auth_title; 'Restrict editing'; end
def label_edit_user_auth_description
  'Do you permit only registrated users to edit?'
end
def label_edit_user_auth_candidate
  [ 'Yes', 'No' ]
end
