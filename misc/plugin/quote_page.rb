# $Id: quote_page.rb,v 1.3 2004-12-24 16:53:33 koma2 Exp $
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
    tokens = @conf.parser.new(@conf).parse(@db.exist?(name) ? @db.load(name) : %Q|[[#{name}]]|)
    @conf.formatter.new(remap_headings(tokens, top_wanted), @db, self, @conf).to_s
  else
    ''
  end
end

