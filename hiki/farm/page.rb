# -*- coding: utf-8 -*-
require 'erb'
require 'hiki/util'

module Hiki
  module Farm
    class Page
      include ::Hiki::Util
      attr_reader :headings

      def initialize(template_dir)
        @headings = {
          'type' => 'text/html; charset=UTF-8'
        }

        @template_dir = template_dir
      end

      def to_s
        erb = ERB.new(template.untaint)
        erb.result(binding)
      end

      private
      def template
        File.read("#{@template_dir}/#{template_name}".untaint)
      end
    end

    class ErrorPage < Page
      def initialize(template_dir, author, mail, css, title, msg)
        super(template_dir)
        @author = author
        @mail = mail
        @css = css
        @title = title
        @msg = msg
      end

      private
      def template_name
        'error.html'
      end
    end

    class IndexPage < Page
      def initialize(conf, manager, hikifarm_uri, message)
        super(conf.hikifarm_template_dir)
        @conf           = conf
        @manager        = manager
        @hikifarm_uri   = hikifarm_uri
        @author         = conf.author
        @mail           = conf.mail
        @css            = conf.css
        @title          = conf.title
        @header_content = load_part(conf.header)
        @footer_content = load_part(conf.footer)
        @msg            = message
      end

      private

      def load_part(file)
        if file
          if File.exist?(file)
            File.read(file).untaint
          else
            error_msg("!! #{file} does not exist !!")
          end
        end
      end

      def error_msg(msg)
        if msg then
          %Q|<p class="message">#{msg}</p>\n|
        else
          ''
        end
      end

      def rss_href
        "#{@hikifarm_uri}#{@manager.command_query(Hiki::Farm::RSSPage.command_name)}"
      end

      def template_name
        'index.html'
      end

      def wikilist_table
        r = ''
        r = "<p>全 #{@manager.wikis_num} Wiki / #{@manager.pages_num} ページ (* は差分へのリンク)</p>\n"
        r << "<table>\n"
        r << %Q!<tr><th>Wiki の名前</th><th>最終更新時刻 / 最終更新ページ</th></tr>!
        wikilist = @manager.wikilist.sort{ |a,b| a.mtime <=> b.mtime }.reverse
        wikilist.each do |wiki|
          page = escape_html(unescape(wiki.last_modified_page))
          r << %Q!<tr>!
          r << %Q!<td><a href="#{wiki.name}/">#{escape_html(wiki.title)}</a></td>!
          r << %Q!<td>#{wiki.mtime.strftime("%Y/%m/%d %H:%M")}!
          r << %Q! <a href="#{wiki.name}/?c=diff;p=#{wiki.last_modified_page}">*</a>\n!
          r << %Q! <a href="#{wiki.name}/?#{wiki.last_modified_page}">#{page}</a></td></tr>\n!
        end
        # @headings['Last-Modified'] = CGI::rfc1123_date( wikilist[0].mtime ) unless wikilist.empty?
        r << "</table>\n"
      end
    end

    # TODO: refactor
    class RSSPage < Page
      class << self
        def command_name
          'rss'
        end
      end

      def initialize(farm, hikifarm_uri, template_dir, hikifarm_description,
                     author, mail, title)
        super(template_dir)
        @manager = farm
        @hikifarm_uri = hikifarm_uri
        @hikifarm_base_uri = @hikifarm_uri.sub(%r|[^/]*$|, '')
        @hikifarm_description = hikifarm_description
        @author = author
        @mail = mail
        @title = title
        @wikilist = @manager.wikilist.sort_by{|x| x.mtime}.reverse[0..14]
        setup_headings
      end

      private
      def template_name
        'rss.rdf'
      end

      def setup_headings
        @headings['type'] = 'text/xml'
        @headings['charset'] = 'EUC-JP'
        @headings['Content-Language'] = 'ja'
        @headings['Pragma'] = 'no-cache'
        @headings['Cache-Control'] = 'no-cache'
        lm = last_modified
        # @headings['Last-Modified'] = CGI.rfc1123_date(lm) if lm
      end

      def last_modified
        if @wikilist.empty?
          nil
        else
          @wikilist.first.mtime
        end
      end

      def rss_uri
        "#{@hikifarm_uri}#{@manager.command_query(self.class.command_name)}"
      end

      def tag(name, content)
        "<#{name}>#{escape_html(content)}</#{name}>"
      end

      def dc_prefix
        "dc"
      end

      def content_prefix
        "content"
      end

      def dc_tag(name, content)
        tag("#{dc_prefix}:#{name}", content)
      end

      def content_tag(name, content)
        tag("#{content_prefix}:#{name}", content)
      end

      def dc_language
        dc_tag("language", "ja-JP")
      end

      def dc_creator
        version = "#{HIKIFARM_VERSION} (#{HIKIFARM_RELEASE_DATE})"
        creator = "HikiFarm version #{version}"
        dc_tag("creator", creator)
      end

      def dc_publisher
        dc_tag("publisher", "#{@author} <#{@mail}>")
      end

      def dc_rights
        dc_tag("rights", "Copyright (C) #{@author} <#{@mail}>")
      end

      def dc_date(date)
        if date
          dc_tag("date", date.iso8601)
        else
          ""
        end
      end

      def rdf_lis(indent='')
        @wikilist.collect do |wiki|
          %Q[#{indent}<rdf:li rdf:resource="#{wiki_uri(wiki)}"/>]
        end.join("\n")
      end

      def rdf_items(indent="")
        @wikilist.collect do |wiki|
          <<-ITEM
#{indent}<item rdf:about="#{wiki_uri(wiki)}">
#{indent}  #{tag('title', wiki.title)}
#{indent}  #{tag('link', wiki_uri(wiki))}
#{indent}  #{tag('description', wiki_description(wiki))}
#{indent}  #{dc_date(wiki.mtime)}
#{indent}  #{content_encoded(wiki)}
#{indent}</item>
      ITEM
        end.join("\n")
      end

      def wiki_uri(wiki)
        "#{@hikifarm_base_uri}#{wiki.name}/"
      end

      def wiki_description(wiki)
        "「#{unescape(wiki.last_modified_page)}」ページが変更されました．"
      end

      def content_encoded(wiki)
        return '' if wiki.pages.empty?
        base_uri = wiki_uri(wiki)
        content = "<div class='recent-changes'>\n"
        content << "  <ol>\n"
        wiki.pages.each do |page|
          content << "    <li>"
          content << "<a href='#{base_uri}?c=diff;p=#{page[:name]}'>"
          content << "*</a>\n"
          content << "<a href='#{base_uri}?#{page[:name]}'>"
          content << "#{escape_html(unescape(page[:name]))}</a>"
          content << "(#{escape_html(modified(page[:mtime]))})"
          content << "</li>\n"
        end
        content << "  </ol>\n"
        content << "</div>\n"
        content_tag("encoded", content)
      end

      # from RWiki
      def modified(t)
        return '-' unless t
        dif = (Time.now - t).to_i
        dif = dif / 60
        return "#{dif}m" if dif <= 60
        dif = dif / 60
        return "#{dif}h" if dif <= 24
        dif = dif / 24
        return "#{dif}d"
      end
    end
  end
end
