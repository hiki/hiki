# $Id: quote_page.rb,v 1.4 2005-06-27 05:54:26 fdiary Exp $
# Copyright (C) 2003 OZAWA Sakuro <crouton@users.sourceforge.jp>

add_body_enter_proc {
  @quote_page_quoted = []
  ''
}

def quote_page(name, top_wanted=1)
  unless @quote_page_quoted.include?(name)
    @quote_page_quoted << name
    tokens = @conf.parser.new(@conf).parse(@db.exist?(name) ? @db.load(name) : %Q|[[#{name}]]|)
    @conf.formatter.new(remap_headings(tokens, top_wanted), @db, self, @conf).to_s
  else
    ''
  end
end

def remap_headings(tokens, top_mapped=1)
  top_real = tokens.select {|t| /heading([1-5])_(open|close)/ =~ t[:e].id2name
}.collect{|t| t[:lv]}.min 
  if top_real
    tokens.collect do |t|
      if /heading([1-5])_(open|close)/ =~ t[:e].id2name
        lv = t[:lv] + (top_mapped - top_real)
        lv = [[lv, 1].max, 5].min
        {:e => "heading#{lv}_#{$2}".intern, :lv => lv}
      else
        t
      end
    end
  else
    tokens
  end
end

export_plugin_methods(:quote_page)
