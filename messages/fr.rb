# $Id: fr.rb,v 1.3 2004-04-02 00:51:24 hitoshi Exp $
# fr.rb
#
# Copyright (C) 2003 Laurent Sansonetti <laurent@datarescue.be>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
# Original file is ja.rb:
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
module Hiki
  module Messages
    def msg_recent; ' Modifications récentes' end
    def msg_create; 'Créer' end
    def msg_diff; 'Différences' end
    def msg_edit; 'Editer' end
    def msg_search; 'Chercher' end
    def msg_admin; 'Administration' end
    def msg_search_result; 'Résultats de la recherche' end
    def msg_search_hits; '\'%1$s\': %3$d page(s) trouvées dans %2$d pages.' end
    def msg_search_not_found; '\'%s\' introuvable.' end
    def msg_search_comment; 'Rechercher sur le site entier.  Ignore la casse.  Hiki renvoie les pages contenant tous les mots de votre requête.' end
    def msg_frontpage; 'Accueil' end
    def msg_hitory; 'Historique' end
    def msg_index; 'Index' end
    def msg_recent_changes; 'Changements' end
    def msg_newpage; 'Nouveau' end
    def msg_no_recent; '<P>Pas de données.</P>' end
    def msg_thanks; 'Merci.' end
    def msg_save_conflict; 'Il y a eu des conflits lors de la mise-à-jour.  Vos modifications n\'ont pas été sauvées.  Sauvez temporairement vos modifications dans un éditeur, rechargez la page et ré-essayez l\'édition à nouveau.' end
    def msg_time_format; "%Y-%m-%d #DAY# %H:%M:%S" end
    def msg_date_format; "%Y-%m-%d " end
    def msg_day; %w(Dimanche Lundi Mardi Mercredi Jeudi Vendredi Samedi) end
    def msg_preview; 'Ceci est une prévisualisation de la page.  Si tout est correct, veuillez confirmer en cliquant sur le bouton Sauver.' end
    def msg_mail_on; 'Envoyer un e-mail de notification' end
    def msg_mail_off; 'Ne pas envoyer un e-mail de notification' end
    def msg_use; 'Utiliser' end
    def msg_unuse; 'Ne pas utiliser' end
    def msg_password_title; 'Mot de passe administrateur' end
    def msg_password_enter; 'Veuillez entrer le mot de passe administrateur.' end
    def msg_password; 'Mot de passe' end
    def msg_ok; 'OK' end
    def msg_invalid_password; 'Mot de passe incorrect.  Vos modifications n\'ont pas encore été sauvegardées.' end
    def msg_save_config; 'Modifications sauvées' end
    def msg_freeze; 'Cette page est gelée.  Vous avez besoin du mot de passe administrateur pour continuer.' end
    def msg_freeze_mark; '[Geler]' end
    def msg_already_exist; 'Cette page a existe déjà.' end
    def msg_page_not_exist; 'Cette page n\'existe pas.  Veuillez la remplir par vous-même ;-)' end
    def msg_invalid_filename(s); "Caractère invalide détecté, ou taille maximale dépassée (#{s} octets).  Veuillez choisir un nouveau titre pour la page." end
    def msg_delete; 'Supprimé.' end
    def msg_delete_page; 'Cette page est supprimée.' end
    def msg_follow_link; 'Cliquez sur le lien ci-dessous pour afficher votre page: ' end
    def msg_match_title; '[correspondance dans le titre]' end
    def msg_match_keyword; '[correspondance dans un mot clef]' end
    def msg_duplicate_page_title; 'Une page portant le même nom existe déjà.' end
    def msg_missing_anchor_title; 'Create new %s and edit.' end
  end
end
