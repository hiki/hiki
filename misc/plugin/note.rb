# $Id: note.rb,v 1.2 2005-03-05 15:24:28 hitoshi Exp $
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>
# based on joesaisan's idea <http://joesaisan.tdiary.net/20050222.html#p02>

def note_orig_page
  if /\A#{Regexp.escape(note_prefix)}/ =~ @page
    hiki_anchor( CGI::escape( $' ), page_name( $' ) )
  end
end

add_menu_proc do
  if /\A#{Regexp.escape(note_prefix)}/ =~ @page then
    hiki_anchor( CGI::escape( $' ), CGI::escapeHTML( label_note_orig ) )
  else
    page = note_prefix + @page
    text = @db.load( page )
    if text.nil? || text.empty?
      @conf['note.template'] ||= label_note_template_default
      %Q|<a href="#{@conf.cgi_name}?c=create;key=#{CGI::escape( page )};text=#{CGI::escape( @conf['note.template'] )}">#{CGI::escapeHTML( label_note_link )}</a>|
    else
      hiki_anchor( CGI::escape( page ), CGI::escapeHTML( label_note_link ) )
    end
  end
end if @page and auth?

def saveconf_note
  if @mode == 'saveconf' then
    @conf['note.template'] = @cgi.params['note.template'][0]
  end
end

add_conf_proc('note', label_note_config) do
  saveconf_note
  @conf['note.template'] ||= label_note_template_default
  str = <<-HTML
  <h3 class="subtitle">#{label_note_template}</h3>
  <p><textarea name="note.template" cols="60" rows="8">#{CGI::escapeHTML( @conf['note.template'] )}</textarea></p>
  HTML
  str
end
