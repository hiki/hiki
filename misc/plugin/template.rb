# $Id: template.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
#

def template_label
  'テンプレート'
end

def template_select_label
  '読込'
end

def templates
  keyword = @options['template.keyword']
  if keyword 
    @db.select {|p| p[:keyword] and p[:keyword].index(keyword)}
  else
    @db.select {|p| true}
  end
end

def template_form
  pages = templates.sort {|a,b| a.downcase <=> b.downcase}
  
  if pages.size > 0
    s = <<EOS
<div>
  #{template_label}:
  <input type="hidden" name="p" value="#{@page}">
  <input type="hidden" name="plugin" value="load_template">
  <select name="template">
EOS

  pages.each do |p|
   p = p.unescape.escapeHTML
   s << %Q!<option value="#{p}"#{'selected' if @options['template.default'] == p.unescapeHTML}>#{p}!
  end
  s << <<EOS
  </select>
  <input type="submit" name="edit_form_button" value="#{template_select_label}">
</div>
EOS
  else
    ''
  end
end

def load_template
  tmpl_name = @cgi.params['template'][0]
  page = @cgi.params['p'][0] ? @cgi.params['p'][0] : 'FrontPage'
  
  @text = if tmpl_name
    @db.load(tmpl_name)
  else
    ''
  end
end

add_edit_proc {
  if @text.size == 0
    tmpl  = @options['template.default']
    tmpl  = templates[0] if !tmpl and templates.size == 1
    @text = @db.load(tmpl) if tmpl and @options['template.autoinsert']
  end
  template_form
}
