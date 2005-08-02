# $Id: edit_user.rb,v 1.1 2005-08-02 13:37:41 yanagita Exp $
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

def label_edit_user_config; 'Benutzerverwaltung'; end
def label_edit_user_title; 'Benutzer l&ouml;schen / Passw&ouml;rter &auml;ndern'; end
def label_edit_user_add_title; 'Benutzer hinzuf&uuml;gen'; end
def label_edit_user_description
	'Jede Zeile bedeutet genau einen Benutzer, jede Zeile in der Form von "name&nbsp;password".'
end
def label_edit_user_auth_title; 'Seitenbearbeitung'; end
def label_edit_user_auth_description
  'D&uuml;rfen nur registrierte Benutzer Seiten editieren?'
end
def label_edit_user_auth_candidate
  [ 'Ja', 'Nein' ]
end
def label_edit_user_delete; 'L&ouml;schen'; end
def label_edit_user_name; 'Name'; end
def label_edit_user_new_password; 'Neues Passwort'; end

