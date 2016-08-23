def note_prefix; 'Note-'; end
def label_note_config; 'Notiz'; end
def label_note_link; 'Notiz'; end
def label_note_orig; 'Original'; end
def label_note_template; 'Dokumentenvorlage einer neuen Notiz.'; end
def label_note_template_default
  str = <<-END
Dies ist eine Notiz zu {{note_orig_page}}.
----
{{bbs}}
  END
end
