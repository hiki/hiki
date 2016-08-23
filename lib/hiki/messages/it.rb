# it.rb
#
# Copyright (C) 2003 Luigi Maselli <metnik@tiscali.it>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
# Original file is ja.rb:
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
module Hiki
  module Messages::It
    Messages.register(:it, self)
    def msg_recent; "Recente" end
    def msg_create; "Crea" end
    def msg_diff; "Differenze" end
    def msg_edit; "Modifica" end
    def msg_search; "Cerca" end
    def msg_admin; "Amministratore" end
    def msg_login; "Login" end
    def msg_logout; "Logout" end
    def msg_search_result; "Risultati trovati" end
    def msg_search_hits; '\'%1$s\': %3$d pagina(e) sono trovati in %2$d pagine.' end # da verificare
    def msg_search_not_found; '\'%s\'non trovato.' end
    def msg_search_comment; "Cerca in questo sito. Ignora MAIUSCOLO/minuscolo. Hiki ricerca le pagine che contengono tutte le parole inserite" end
    def msg_frontpage; "Alto" end
    def msg_hitory; "Cronologia" end
    def msg_index; "Indici" end
    def msg_recent_changes; "Ultime modifiche" end
    def msg_newpage; "Nuova" end
    def msg_no_recent; "<P>Non ci sono dati.</P>" end
    def msg_thanks; "Grazie." end
    def msg_save_conflict; 'Conflitto nell\'aggiornamento. Le modifiche non sono state salvate. Copia le tue modifiche, ricarica le pagine e prova a modificarle di nuovo.' end
    def msg_time_format; "%d-%m-%Y #DAY# %H:%M:%S" end
    def msg_date_format; "%d-%m-%Y " end
    def msg_day; %w(Dom Lun Mar Mer Gio Ven Sab) end
    def msg_preview; 'Conferma il risultato sotto e salvalo cliccando sul pulsante Salva se non ci sono errori -&gt;<a href="#form">Modulo</a>' end
    def msg_mail_on; "Invia updated-mail" end # da verificare
    def msg_mail_off; "Non inviare updated-mail" end # da verificare
    def msg_use; "Usa" end
    def msg_unuse; "Non usare" end
    def msg_login_info; '(TRANSLATE PLEASE) If you want to login as an administrator, type \'admin\' in the Name field.' end
    def msg_login_failure; "(TRANSLATE PLEASE) Wrong name or password." end
    def msg_name; "Nomare" end
    def msg_password; "Password" end
    def msg_ok; "OK" end
    def msg_invalid_password; "Password non corretta. Le tue modifiche non sono ancora state salvate." end
    def msg_save_config; "Modifiche salvate" end
    def msg_freeze; 'Questa pagina ? bloccata. Ti serve la password dell\'amministratore per salvare.' end
    def msg_freeze_mark; "[Bloccata]" end
    def msg_already_exist; "La pagina gi? esistente." end
    def msg_page_not_exist; "La pagina non esiste. Createla! :-)" end
    def msg_invalid_filename(s); "Includi i caratteri invalidi, o ? oltre la lunghezza massima(#{s}byte). Cambia il nome della pagina." end
    def msg_delete; "Cancellato" end
    def msg_delete_page; "Pagina cancellata." end
    def msg_follow_link; "Segui il collegamento: " end
    def msg_match_title; "[corrispondente in titolo]" end
    def msg_match_keyword; "[corrispondente nella chiave di ricerca]" end
    def msg_duplicate_page_title; "Titolo della pagina gi? esistente." end
    def msg_missing_anchor_title; "Create new %s and edit." end
    # (config)
    def msg_config; "Configurazione Hiki"; end
    # (diff)
    def msg_diff_add; 'Le linee aggiunte sono mostrate come <ins class="added">qui</ins>.'; end
    def msg_diff_del; 'Le linee rimosse sono mostrate come <del class="deleted">qui</del>.'; end
    # (edit)
    def msg_title; "Titolo pagina"; end
    def msg_keyword_form; "Parole chiave (Scrivile una ogni riga)"; end
    def msg_freeze_checkbox; "Blocca la pagina corrente."; end
    def msg_preview_button; "Anteprima"; end
    def msg_save; "Salva"; end
    def msg_update_timestamp; "(TRANSLATE PLEASE) Update timestamp"; end
    def msg_latest; "Riferimento versione recente"; end
    def msg_rules; %Q|Vedi <a href="#{@cgi_name}?TextFormattingRules">TextFormattingRules</a> se serve.|; end
    # (view)
    def msg_last_modified; "Ultima modifica"; end
    def msg_keyword; "Parola chiave"; end
    def msg_reference; "Referenze"; end
  end
end
