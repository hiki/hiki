# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

module Hiki
  module Formatter
    class Base
      H2_RE = /^<h2>.*<a name=/

      def apply_tdiary_theme(orig_html)
        return orig_html if @conf.mobile_agent?
        section = ""
        title   = ""
        html    = ""

        orig_html.each_line do |line|
          if H2_RE =~ line
            html << tdiary_section(title, section) unless title.empty? && section.empty?
            section = ""
            title = line
          else
            section << line
          end
        end
        html << tdiary_section(title, section)
      end

      private

      def tdiary_section(title, section)
        title = title.strip
        section = section.strip
        return "" if title.empty? && section.empty?
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
end
