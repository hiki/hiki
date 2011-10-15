# -*- coding: utf-8 -*-
require 'erb'
require 'uri'
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
        URI.join(@hikifarm_uri, RSSPage.page_name)
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

    class RSSPage
      include ::Hiki::Util

      class << self
        def command_name
          'rss'
        end

        def page_name
          'hikifarm.rss'
        end
      end

      def initialize(conf, manager, hikifarm_uri)
        @conf = conf
        @manager = manager
        @hikifarm_uri = hikifarm_uri
      end

      def to_s
        make_rss.to_s
      end

      private

      def make_rss
        require 'rss'
        rss = RSS::Maker.make("1.0") do |maker|
          maker.channel.about = URI.join(@hikifarm_uri, self.class.page_name).to_s
          maker.channel.title = @conf.title
          maker.channel.description = @conf.hikifarm_description
          maker.channel.link = @hikifarm_uri

          maker.items.do_sort  = true
          maker.items.max_size = 15

          @manager.wikilist.each do |wiki|
            maker.items.new_item do |item|
              item.link  = URI.join(@hikifarm_uri, wiki.name)
              item.title = wiki.title
              item.date  = wiki.mtime
              item.description = wiki.description
              content = %Q!<div class="recent-changes">\n!
              content << "  <ol>\n"
              wiki.pages.each do |page|
                content << "    <li>"
                content << %Q!<a href="">*</a>!
                content << %Q!<a href="">#{escape_html(unescape(page[:name]))}</a>!
                content << %Q!(#{escape_html(modified(page[:mtime]))})!
                content << "</li>\n"
              end
              content << "  </ol>\n"
              content << %Q!</div>!
              item.content_encoded = content
            end
          end
        end
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
