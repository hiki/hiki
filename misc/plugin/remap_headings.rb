# $Id: remap_headings.rb,v 1.2 2004-03-01 09:50:45 hitoshi Exp $
# Copyright (C) 2003 OZAWA Sakuro <crouton@users.sourceforge.jp>

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

