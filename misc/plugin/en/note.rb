def note_prefix; 'Note-'; end
def label_note_config; 'Note'; end
def label_note_link; 'Note'; end
def label_note_orig; 'Original'; end
def label_note_template; 'The template of a new note page'; end
def label_note_template_default
  str = <<-END
This is a note page for {{note_orig_page}}.
----
{{bbs}}
  END
end
