# $Id: quote_page.rb,v 1.5 2005-12-28 22:42:55 fdiary Exp $
# Copyright (C) 2003 OZAWA Sakuro <crouton@users.sourceforge.jp>

add_body_enter_proc {
  @quote_page_quoted = []
  ''
}

def quote_page(name, top_wanted=1)
  unless @quote_page_quoted.include?(name)
    @quote_page_quoted << name
    tokens = @conf.parser.new(@conf).parse(@db.exist?(name) ? @db.load(name) : %Q|[[#{name}]]|, top_wanted.to_i + 1)
    @conf.formatter.new(tokens, @db, self, @conf).to_s
  else
    ''
  end
end

export_plugin_methods(:quote_page)
