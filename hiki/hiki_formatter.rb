# $Id: hiki_formatter.rb,v 1.4 2004-08-31 07:25:46 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

module Hiki
  class HikiFormatter
    def apply_tdiary_theme(html)
      section = ''
      title   = ''
      tdiary_html    = ''
      first_f = false

      html.each do |line|
        if /(.*?)(<h2>.+)/ =~ line
           section << $1
          if section.size > 0 or first_f
            tdiary_html << tdiary_section(title, section)
            section = ''
          end
          first_f = true
          title = $2
        else
         section << line
        end
     end
     tdiary_html << tdiary_section(title, section)
    end

  private
    def tdiary_section(title, section)
<<"EOS"
<div class="day">
  #{title}
  <div class="body">
    <div class="section">
      #{section}
    </div>
  </div>
</div>
EOS
    end
  end
end
