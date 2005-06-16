def history_label
  'History'
end

module Hiki
  class History < Command
    private

    def history_label
      'History'
    end

    def history_th_label
      ['Rev', 'Time', 'Changes', 'Operation', 'Log']
    end

    def history_not_supported_label
      'History is not available in current configuration.'
    end

    def history_revert_label
      'Revert to this version'
    end

    def history_diffto_current_label
      'Diff to current'
    end

    def history_view_this_version_src_label
      'See the source of this version'
    end

    def history_backto_summary_label
      'Back to History page'
    end

    def history_add_line_label
      'Added words are showed as <b class="added">here</b>.'
    end

    def history_delete_line_label
      'Removed words are showed as <s class="deleted">here</s>.'
    end
  end
end
