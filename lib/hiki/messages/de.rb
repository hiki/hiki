# de.rb
#
# Copyright (C) 2005 Kashia Buch <kashia@vfemail.net>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
# Original file is ja.rb:
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
module Hiki
  module Messages::De
    Messages.register(:de, self)
    def msg_recent; "Neu" end
    def msg_create; "Erstellen" end
    def msg_diff; "Diff" end
    def msg_edit; "Editieren" end
    def msg_search; "Suchen" end
    def msg_admin; "Admin" end
    def msg_login; "Login" end
    def msg_logout; "Logout" end
    def msg_search_result; "Suchergebnisse" end
    def msg_search_hits; '%3$d Seite(n) mit der Phrase \'%1$s\' wurden in %2$d Seiten gefunden.' end
    def msg_search_not_found; 'Es wurden keine Seiten mit der Phrase \'%s\' gefunden.' end
    def msg_search_comment; "Durchsucht alle Seiten, ignoriert Gro&szlig;- und Kleinschreibung und liefert alle Seiten die die W&ouml;rter in der Anfrage enthalten." end
    def msg_frontpage; "Top" end
    def msg_hitory; "Verlauf" end
    def msg_index; "Index" end
    def msg_recent_changes; "Ver&auml;nderungen" end
    def msg_newpage; "Neu" end
    def msg_no_recent; "<P>Keine Daten.</P>" end
    def msg_thanks; "Danke f&uuml; das Update." end
    def msg_save_conflict; 'Es gibt einen Konflikt mit Ihrem Update. Kopieren Sie den Inhalt unten in ein Textverarbeitungsprogramm und editieren Sie die Seite neu indem Sie erneut auf "Editieren" klicken.' end
    def msg_time_format; "%Y-%m-%d #DAY# %H:%M:%S" end
    def msg_date_format; "%Y-%m-%d " end
    def msg_day; %w(Son Mon Die Mit Don Fre Sam) end
    def msg_preview; '&Uuml;berpr&uuml;fen sie die Eingabe. Wenn keine Probleme vorhanden sind, sichern Sie die Seite indem sie auf "Speichern" klicken. -&gt;<a href="#form">Formular</a>' end
    def msg_mail_on; "Sende Email bei ver&auml;nderungen" end
    def msg_mail_off; "Keine Email bei ver&auml;nderungen" end
    def msg_use; "Benutze" end
    def msg_unuse; "Benutze kein" end
    def msg_login_info; 'Wenn Sie sich als Administrator anmelden wollen, tippen Sie \'admin\' in das Namensfeld.' end
    def msg_login_failure; "Falscher Benutzername oder Passwort." end
    def msg_name; "Name" end
    def msg_password; "Passwort" end
    def msg_ok; "OK" end
    def msg_invalid_password; "Falsches Passwort, Ihre &Auml;nderungen wurden nicht gespeichert." end
    def msg_save_config; "Ihre Konfigurations-&Auml;nderungen wurden gespeichert." end
    def msg_freeze; "Diese Seite ist eingefrohren. Sie brauchen ein Administratorpasswort um diese Seite zu ver&auml;ndern." end
    def msg_freeze_mark; "[Eingefrohren]" end
    def msg_already_exist; "Diese Seite existiert bereits." end
    def msg_page_not_exist; "Diese Seite existiert noch nicht, Sie k&ouml;nnen sie aber ohne weiteres erstellen." end
    def msg_invalid_filename(s); "Der Seitenname ent&auml;lt ung&uuml;ltige Zeichen oder ist gr&ouml;&szlig;er als die maximale anzahl von #{s} Zeichen. Bitte w&auml;hlen Sie einen anderen Seitennamen." end
    def msg_delete; "Gel&ouml;scht" end
    def msg_delete_page; "Die Seite wurde gel&ouml;scht." end
    def msg_follow_link; "Klicken Sie den folgenden Link um Ihre Seite zu sehen: " end
    def msg_match_title; "(&Uuml;bereinstimmung im Titel)" end
    def msg_match_keyword; "(&Uuml;bereinstimmung im Stichwort)" end
    def msg_duplicate_page_title; "Dieser Seitentitel existiert bereits." end
    def msg_missing_anchor_title; "Erstelle und bearbeite Seite %s." end
    # (config)
    def msg_config; "Hiki Configuration"; end
    # (diff)
    def msg_diff_add; 'Hinzgef&uuml;gte Teile werden wie <ins class="added">hier</ins> angezeigt.'; end
    def msg_diff_del; 'Entfernte Teile werden wie <del class="deleted">hier</del> angezeigt.'; end
    # (edit)
    def msg_title; "Titel"; end
    def msg_keyword_form; "Stichw&ouml;rter (ein Stichwort pro Zeile)"; end
    def msg_freeze_checkbox; "Seite einfrieren."; end
    def msg_preview_button; "Vorschau"; end
    def msg_save; "Speichern"; end
    def msg_update_timestamp; "Timestamp updaten"; end
    def msg_latest; "Neueste Version"; end
    def msg_rules; "Siehe <a href=\"#{@cgi_name}?TextFormattingRules\">Formatierungsregeln</a> f&uuml;r Hilfe beim Editieren."; end
    # (view)
    def msg_last_modified; "Zuletzt ge&auml;ndert"; end
    def msg_keyword; "Stichworte"; end
    def msg_reference; "Referenzen"; end
  end
end
