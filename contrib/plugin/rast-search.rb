require 'rast'

module Hiki
  class RastSearch < Command
    MAX_PAGES = 10
    NUM = 10

    def rast_output(s)
      title_str = @key.empty? ? @conf.msg_search : @conf.msg_search_result
      str = <<-EOS
  <form class="update" action="./">
    <h2>#{@conf.site_name.escapeHTML} - #{title_str.escapeHTML}</h2>
    <p>#{@conf.msg_search_comment.escapeHTML}</p>
    <p><input type="text" name="key" size="20" value="#{@key.escapeHTML}">
    <input type="hidden" name="c" value="search">
    <input type="submit" name="search" value="#{@conf.msg_search.escapeHTML}"></p>
  </form>
EOS
      parser = @conf.parser::new(@conf)
      tokens = parser.parse('')
      formatter = @conf.formatter::new(tokens, @db, @plugin, @conf)
      @page  = Page::new(@cgi, @conf)
      data   = Util::get_common_data(@db, @plugin, @conf)
      @plugin.hiki_menu(data, @cmd)
      data[:title]      = title(title_str)
      data[:view_title] = title_str
      data[:body]       = formatter.apply_tdiary_theme(str + s)
      @cmd = 'plugin' # important!!!
      generate_page(data) # private method inherited from Command class
    end

    def search
      db_list = @conf.options['rast-search.db_list'] || [@conf.options['rast-search.db_path'] || "#{@conf.cache_path}/rast"]
      @key = @cgi['key']
      if @key.empty?
        rast_output('')
      else
        @start = @cgi["start"].to_i
        begin
          rast_db_list = db_list.collect do |db_name|
            Rast::DB.open(db_name.untaint, Rast::DB::RDONLY)
          end
          Rast::Merger.open(rast_db_list) do |db|
            options = create_search_options
            @result = db.search(@key, options)
            if @result.hit_count ==0
              rast_output("<p>#{(@conf.msg_search_not_found % @key).escapeHTML}</p>")
            else
              rast_output(format_result)
            end
          end
        rescue
          rast_output("<p>Error : #{$!.message.escapeHTML}</p>")
        ensure
          rast_db_list.each do |db|
            db.close if db
          end
        end
      end
    end

    def format_result
      head = "<p>#{(@conf.msg_search_hits % [@key, @db.page_info.size, @result.hit_count]).escapeHTML} (#{@start + 1} - #{@start + @result.items.size})</p>\n"
      ret = %Q(<dl class="search">\n)
      @result.items.each do |item|
        uri, title, last_modified = *item.properties
        title = uri if title.empty?
        summary = item.summary.escapeHTML || ''
        for term in @result.terms
          summary.gsub!(Regexp.new(Regexp.quote(term.term.escapeHTML), true, "e"),
                        "<strong>\\&</strong>")
        end
        ret << %Q|<dt><a href="#{uri.escapeHTML}">#{title.escapeHTML}</a></dt>\n|
        ret << %Q|<dd>#{summary}<br><a href="#{uri.escapeHTML}">#{uri.escapeHTML}</a></dd>\n|
      end
      ret << "</dl>\n"
      head + ret + format_links
    end

    def format_links
      page_count = (@result.hit_count - 1) / NUM + 1

      current_page = @start / NUM + 1
      first_page = current_page - (MAX_PAGES / 2 - 1)
      if first_page < 1
        first_page = 1
      end
      last_page = first_page + MAX_PAGES - 1
      if last_page > page_count
        last_page = page_count
      end
      buf = %Q|<p id="navi" class="infobar">\n|
      if current_page > 1
        buf.concat(format_link("&lt;", @start - NUM, NUM))
      end
      if first_page > 1
        buf.concat("... ")
      end
      for i in first_page..last_page
        if i == current_page
  	buf.concat("#{i} ")
        else
  	buf.concat(format_link(i.to_s, (i - 1) * NUM, NUM))
        end
      end
      if last_page < page_count
        buf.concat("... ")
      end
      if current_page < page_count
        buf.concat(format_link("&gt;", @start + NUM, NUM))
      end
      buf.concat("</p>\n")
      return buf
    end
  
    def format_link(label, start, num)
      return format(%Q|<a href="%s?c=search;key=%s;start=%d">%s</a> |,
                     @conf.cgi_name, @key.escape, start, label)
    end

    def create_search_options
      options = {
        "properties" => [
          "uri", "title", "last_modified"
        ],
        "need_summary" => true,
        "summary_nchars" => 200,
        "start_no" => @start,
        "num_items" => NUM,
      }
    end
  end
end

def search
  Hiki::RastSearch.new(@cgi, @db, @conf).search
end

add_body_enter_proc do
  add_plugin_command('search', nil)
end
