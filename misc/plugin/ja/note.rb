def note_prefix; 'Note-'; end
def label_note_config; 'ノート'; end
def label_note_link; 'ノート'; end
def label_note_orig; '元のページ'; end
def label_note_template; '新規ノートページのテンプレート'; end
def label_note_template_default
  str = <<-END
{{note_orig_page}} のノートのページです。
----
{{bbs}}
  END
end
