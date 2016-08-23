# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
#

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

  unless pages.empty?
    s = <<EOS
<div>
  #{template_label}:
  <input type="hidden" name="p" value="#{h(@page)}">
  <input type="hidden" name="plugin" value="load_template">
  <select name="template">
EOS

  pages.each do |p|
   p = h(unescape(p))
   s << %Q!<option value="#{p}"#{'selected' if @options['template.default'] == unescape_html(p)}>#{p}</option>!
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
  tmpl_name = @request.params['template']
  page = @request.params['p'] ? @request.params['p'] : 'FrontPage'

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

export_plugin_methods(:load_template)

def saveconf_template
  if @mode == 'saveconf' then
    @conf['template.default'] = @request.params['template.default'] && @request.params['template.default'].empty? ? nil : @request.params['template.default']
    @conf['template.keyword'] = @request.params['template.keyword'].empty? ? nil : @request.params['template.keyword']
    @conf['template.autoinsert'] = @request.params['template.autoinsert'] ? true : false
  end
end

add_conf_proc('template', template_label) do
  saveconf_template

  str = <<-HTML
  <h3 class="subtitle">#{label_template_keyword}</h3>
  <p>#{label_template_keyword_desc}</p>
  <p><input type="text" name="template.keyword" value="#{@conf['template.keyword']}" size="10"></p>
  HTML

  pages = templates.sort {|a,b| a.downcase <=> b.downcase}
  unless pages.empty?
    str << <<-HTML
  <h3 class="subtitle">#{label_template_default}</h3>
  <p>#{label_template_default_desc}</p>
  <p><select name="template.default">
    HTML
    pages.each do |p|
      str << %Q|<option value="#{h(p)}"#{@conf['template.default'] == p ? ' selected' : ''}>#{h(p)}</option>\n|
    end
  end

  str << <<-HTML
  </select></p>
  <h3 class="subtitle">#{label_template_autoinsert}</h3>
  <p><input type="checkbox" name="template.autoinsert" value="true"#{@conf['template.autoinsert'] ? ' checked' : ''}>#{label_template_autoinsert_desc}</p>
  HTML
  str
end
