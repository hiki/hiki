# $Id: quote_page.rb,v 1.2 2004-03-01 09:50:45 hitoshi Exp $
# Copyright (C) 2003 OZAWA Sakuro <crouton@users.sourceforge.jp>

add_body_enter_proc {
  @quote_page_quoted = []
  ''
}

def about_quote_page
  <<-EOS
!Syntax
 {{quote_page(PAGE[, TOP_WANTED=1])}}

!Description
This plugin quotes other page in current page.

Optional TOP_WANTED argument determines which level the headings
in original text are mapped to in formatted result.
  EOS
end

def quote_page(name, top_wanted=1)
  unless @quote_page_quoted.include?(name)
    @quote_page_quoted << name
    parser = Parser.new
    tokens = parser.parse(@db.exist?(name) ? @db.load(name) : %Q|[[#{name}]]|)
    HTMLFormatter.new(remap_headings(tokens, top_wanted), @db, self).to_s
  else
    ''
  end
end

