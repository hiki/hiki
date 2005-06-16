def history_label
  '編集履歴'
end

module Hiki
  class History < Command
    private

    def history_label
      '編集履歴'
    end

    def history_th_label
      ['Rev', '時刻', '変更', '操作', 'ログ']
    end

    def history_not_supported_label
      '現在の設定では編集履歴はサポートされていません。'
    end

    def history_revert_label
      'このバージョンに戻す'
    end

    def history_diffto_current_label
      '現在のバージョンとの差分を見る'
    end

    def history_view_this_version_src_label
      'このバージョンのソースを見る'
    end

    def history_backto_summary_label
      '編集履歴ページに戻る'
    end

    def history_add_line_label
      '追加された部分は<ins class="added">このように</ins>表示します。'
    end

    def history_delete_line_label
      '削除された部分は<del class="deleted">このように</del>表示します。'
    end
  end
end
