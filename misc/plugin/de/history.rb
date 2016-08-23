def history_label
  'Verlauf'
end

module Hiki
  class History < Command
    private

    def history_label
      'Verlauf'
    end

    def history_th_label
      ['Rev', 'Datum', '&Auml;nderungen', 'Operation', 'Log']
    end

    def history_not_supported_label
      'Verlauf ist in der derzeitigen Konfiguration nicht m&ouml;glich.'
    end

    def history_revert_label
      'Zu dieser Version zur&uuml;ckkehren'
    end

    def history_diffto_current_label
      'Unterschied zur aktuallen Version'
    end

    def history_view_this_version_src_label
      'Inhalt dieser Version einsehen.'
    end

    def history_backto_summary_label
      'Zur&uuml;ck zur Verlaufs-Seite'
    end

    def history_add_line_label
      'Hinzgef&uuml;gte Teile werden wie <b class="added">hier</b> angezeigt.'
    end

    def history_delete_line_label
      'Entfernte Teile werden wie <s class="deleted">hier</s> angezeigt.'
    end
  end
end
