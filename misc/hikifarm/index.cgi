#!/usr/bin/env ruby

HIKIFARM_VERSION = '0.8.6'
HIKIFARM_RELEASE_DATE = '2006-07-21'

class HikifarmConfig
  attr_reader :ruby, :hiki, :hikifarm_description
  attr_reader :default_pages, :data_root, :repos_type, :repos_root
  attr_reader :title, :css, :author, :mail, :cgi_name, :attach_cgi_name, :header, :footer, :cgi, :hikifarm_template_dir
  
  def initialize
    require 'cgi'
    @cgi = CGI.new
    load
  end

  def load
    # デフォルト設定
    # 前もって定義してないと eval しても残らない
    ruby = '/usr/bin/env ruby'
    hiki = ''
    hikifarm_description = nil
    default_pages = ''
    data_path = ''
    repos_type = nil
    repos_root = nil
    cvsroot = nil
    title = ''
    css = 'theme/hiki/hiki.css'
    author = ''
    mail = ''
    header = nil
    footer = nil
    cgi_name = 'index.cgi'
    attach_cgi_name = nil
    if FileTest::symlink?( __FILE__ ) then
      hikifarm_template_dir = File::dirname( File::expand_path( File::readlink( __FILE__ ) ) ) + '/template'
    else
      hikifarm_template_dir = File::dirname( File::expand_path( __FILE__ ) ) + '/template'
    end

    eval(File.read('hikifarm.conf').untaint)

    @ruby = ruby
    @hiki = hiki
    @hikifarm_description = hikifarm_description || title
    @default_pages = default_pages
    @data_root = data_path # the name `data_path' is unsuitable. It is different from `data_path' of indivisual Hiki.

    @repos_type = repos_type || 'default'
    @repos_root = repos_root

    @title = title
    @css = css
    @author = author
    @mail = mail
    @header = header
    @footer = footer
    @cgi_name = cgi_name
    @attach_cgi_name = attach_cgi_name
    @hikifarm_template_dir = hikifarm_template_dir

    # Support depracated configuration
    if cvsroot then
      @repos_type = 'cvs'
      @repos_root = cvsroot
    end

    if @repos_root && %r!^(/|[a-z]:)! !~ @repos_root
      msg = "Hiki does not support remote repository now. " + 
        "Please modify &quot;repos_root&quot; entry of &quot;hikifarm.conf&quot; file."
      page = ErrorPage.new(@hikifarm_template_dir, @author, @mail, @css, @title, msg)
      body = page.to_s
      print @cgi.header(page.headings)
      print body
    end
  end
end



class Wiki
  attr_reader :name, :title, :mtime, :last_modified_page, :pages_num, :pages
  def initialize(name, data_root)
    @name = name
    @pages_num = 0

    begin
      File.readlines("#{data_root}/#{name}/hiki.conf").each do |line|
        if line =~ /^[@\$]?site_name\s*=\s*(".*")\s*$/
          @title = eval($1.untaint)
        end
      end
    rescue
      @title = "#{name}'s Wiki"
    end

    pages = Dir["#{data_root}/#{name}/text/*"]
    pages.delete_if{|f| File.basename(f) == 'CVS' or File.basename(f) == '.svn' or File.size?(f.untaint).nil?}
    pages = pages.sort_by{|f| File.mtime(f)}
    if pages.empty?
      @last_modified_page = "FrontPage"
      @mtime = Time.at(0)
    else
      @last_modified_page = File.basename(pages[-1])
      @mtime = File.mtime(pages[-1])
    end
    @pages_num = pages.size
    @pages = pages.reverse[0..9].collect do |page|
      {
        :name => File.basename(page),
        :mtime => File.mtime(page),
      }
    end
  end
end

class Hikifarm
  attr_reader :wikilist
  
  def initialize(farm_pub_path, ruby, repos_type, repos_root, data_root)
    require "hiki/repos/#{repos_type}"
    @repos = Hiki::const_get("HikifarmRepos#{repos_type.capitalize}").new(repos_root, data_root)
    @ruby = ruby
    @wikilist = []
    @farm_pub_path = farm_pub_path

    Dir["#{farm_pub_path}/*"].each do |wiki|
      wiki.untaint
      next if not FileTest.directory?(wiki)
      next if FileTest.symlink?(wiki)
      next if not FileTest.file?("#{wiki}/hikiconf.rb")

      begin
        @wikilist << Wiki.new(File.basename(wiki), data_root)
      rescue
      end
    end
  end

  def wikis_num
    @wikilist.size
  end

  def pages_num
    @wikilist.inject(0){|result, wiki| result + wiki.pages_num}
  end

  def create_wiki(name, hiki, cgi_name, attach_cgi_name, data_root, default_pages_path)
    Dir.mkdir("#{@farm_pub_path}/#{name.untaint}")

    File.open("#{@farm_pub_path}/#{name}/#{cgi_name}", 'w') do |f|
      f.puts(index(name, hiki))
      f.chmod(0744)
    end

    if attach_cgi_name
      File.open("#{@farm_pub_path}/#{name}/#{attach_cgi_name}", 'w') do |f|
        f.puts(attach(name, hiki))
        f.chmod(0744)
      end
    end

    File.open("#{@farm_pub_path}/#{name}/hikiconf.rb", 'w') do |f|
      f.puts(conf(name, hiki))
    end

    Dir.mkdir("#{data_root}/#{name}")
    Dir.mkdir("#{data_root}/#{name}/text")
    Dir.mkdir("#{data_root}/#{name}/backup")
    Dir.mkdir("#{data_root}/#{name}/cache")
    require 'fileutils'
    Dir["#{default_pages_path}/*"].each do |f|
      f.untaint
      FileUtils.cp(f, "#{data_root}/#{name}/text/#{File.basename(f)}") if File.file?(f)
    end

    @repos.import(name)
  end

  def command_key
    "c"
  end
    
  def command_query(name)
    "?#{command_key}=#{CGI.escape(name)}"
  end
  
  private
  def conf(wiki, hiki)
<<CONF
hiki=''
eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
__my_wiki_name__ = '#{wiki}'
eval( File::open( "\#{hiki}/hiki.conf" ){|f| f.read.untaint} )
CONF
  end

  def index(wiki, hiki)
<<-INDEX
#!#{@ruby}
hiki=''
eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
$:.unshift "\#{hiki}"
load "\#{hiki}/hiki.cgi"
INDEX
  end

  def attach(wiki, hiki)
<<-INDEX
#!#{@ruby}
hiki=''
eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
$:.unshift "\#{hiki}"
load "\#{hiki}/misc/plugin/attach/attach.cgi"
INDEX
  end

end



class ErbPage
  attr_reader :headings

  def initialize(template_dir)
    @headings = {
      'type' => 'text/html; charset=EUC-JP'
    }

    @template_dir = template_dir
  end

  def to_s
    require 'erb'
    erb = ERB.new(template.untaint)
    erb.result(binding)
  end

  private
  def template
    File.read("#{@template_dir}/#{template_name}".untaint)
  end
end

class ErrorPage < ErbPage
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

class HikifarmIndexPage < ErbPage
  def initialize(farm, hikifarm_uri, template_dir, author, mail, css, title, header_file, footer_file, msg)
    super(template_dir)
    @farm = farm
    @hikifarm_uri = hikifarm_uri
    @author = author
    @mail = mail
    @css = css
    @title = title
    @header_content = if header_file
                        File.exist?(header_file) ? File.read(header_file).untaint : error_msg("!! #{header_file} が存在しません !!")
                      end
    @footer_content = if footer_file
                        File.exist?(footer_file) ? File.read(footer_file).untaint : error_msg("!! #{footer_file} が存在しません !!")
                      end
    @msg = msg
  end

  private
  def error_msg(msg)
    if msg then
      %Q|<p class="message">#{msg}</p>\n|
    else
      ''
    end
  end

  def rss_href
    "#{@hikifarm_uri}#{@farm.command_query(HikifarmRSSPage.command_name)}"
  end

  def template_name
    'index.html'
  end

  def wikilist_table
    r = ''
    r = "<p>全 #{@farm.wikis_num} Wiki / #{@farm.pages_num} ページ (* は差分へのリンク)</p>\n"
    r << "<table>\n"
    r << %Q!<tr><th>Wiki の名前</th><th>最終更新時刻 / 最終更新ページ</th></tr>!
    wikilist = @farm.wikilist.sort{ |a,b| a.mtime <=> b.mtime }.reverse
    wikilist.each do |wiki|
      page = CGI.escapeHTML(CGI.unescape(wiki.last_modified_page))
      r << %Q!<tr>!
      r << %Q!<td><a href="#{wiki.name}/">#{CGI::escapeHTML(wiki.title)}</a></td>!
      r << %Q!<td>#{wiki.mtime.strftime("%Y/%m/%d %H:%M")}!
      r << %Q! <a href="#{wiki.name}/?c=diff;p=#{wiki.last_modified_page}">*</a>\n!
      r << %Q! <a href="#{wiki.name}/?#{wiki.last_modified_page}">#{page}</a></td></tr>\n!
    end
    @headings['Last-Modified'] = CGI::rfc1123_date( wikilist[0].mtime ) unless wikilist.empty?
    r << "</table>\n"
  end
end

class HikifarmRSSPage < ErbPage

  class << self
    def command_name
      'rss'
    end
  end
  
  def initialize(farm, hikifarm_uri, template_dir, hikifarm_description,
                 author, mail, title)
    super(template_dir)
    @farm = farm
    @hikifarm_uri = hikifarm_uri
    @hikifarm_base_uri = @hikifarm_uri.sub(%r|[^/]*$|, '')
    @hikifarm_description = hikifarm_description
    @author = author
    @mail = mail
    @title = title
    @wikilist = @farm.wikilist.sort_by{|x| x.mtime}.reverse[0..14]
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
    @headings['Last-Modified'] = CGI.rfc1123_date(lm) if lm
  end

  def last_modified
    if @wikilist.empty?
      nil
    else
      @wikilist.first.mtime
    end
  end
  
  def rss_uri
    "#{@hikifarm_uri}#{@farm.command_query(self.class.command_name)}"
  end
    
  def tag(name, content)
    "<#{name}>#{CGI.escapeHTML(content)}</#{name}>"
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
    "「#{CGI.unescape(wiki.last_modified_page)}」ページが変更されました．"
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
      content << "#{CGI.escapeHTML(CGI.unescape(page[:name]))}</a>"
      content << "(#{CGI.escapeHTML(modified(page[:mtime]))})"
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

class App
  def initialize(conf)
    @conf = conf
    @farm = Hikifarm.new(File.dirname(__FILE__), @conf.ruby, @conf.repos_type, @conf.repos_root, @conf.data_root)
    @cgi = conf.cgi
  end

  def run
    msg = nil
    page = nil
    if command_name == HikifarmRSSPage.command_name
      require 'time'
      page = HikifarmRSSPage.new(@farm, hikifarm_uri, @conf.hikifarm_template_dir,
                                 @conf.hikifarm_description,
                                 @conf.author, @conf.mail, @conf.title)
    elsif 'POST' == @cgi.request_method and @cgi.params['wiki'][0] and @cgi.params['wiki'][0].length > 0
      begin
        name = @cgi.params['wiki'][0]
        raise '英数字のみ指定できます' if /\A[a-zA-Z0-9]+\z/ !~ name
        @farm.create_wiki(name, @conf.hiki, @conf.cgi_name, @conf.attach_cgi_name, @conf.data_root, @conf.default_pages)

        print @cgi.header({'Location' => hikifarm_uri})
        exit
      rescue
        msg = %Q|#{$!.to_s}\n#{$@.join("\n")}|
      end
    end
    page ||= HikifarmIndexPage.new(@farm, hikifarm_uri, @conf.hikifarm_template_dir, @conf.author, @conf.mail, @conf.css, @conf.title,
                                   @conf.header, @conf.footer, msg)
    body = page.to_s
    print @cgi.header(page.headings)
    print body
  end

  private
  def command_name
    @cgi.params[@farm.command_key][0]
  end
  
  def hikifarm_uri
    server_name = ENV['SERVER_NAME']
    server_port = ENV['SERVER_PORT']
    path = hikifarm_absolute_path
    if /on/i =~ ENV['HTTPS']
      scheme = "https"
      default_port = '443'
    else
      scheme = "http"
      default_port = '80'
    end
    build_uri(scheme, server_name, server_port, default_port, path)
  end

  def hikifarm_absolute_path
    request_uri = ENV['REQUEST_URI']
    script_name = ENV['SCRIPT_NAME'] || ''
    if request_uri
      require 'uri'
      path = URI.parse(request_uri).path
      path = nil if /\A\s*\z/ =~ path
    end
    path ||= script_name
    path.dup.untaint
  end
  
  def build_uri(scheme, name, actual_port, default_port, path)
    port = (actual_port == default_port) ? '' : ":#{actual_port}"
    "#{scheme}://#{name}#{port}#{path}".untaint
  end
end

# main ###############
if __FILE__ == $0 || ENV['MOD_RUBY']
  $SAFE = 1
  $:.delete(".") if File.writable?(".")
  conf = HikifarmConfig.new
  $:.unshift(conf.hiki)
  App.new(conf).run
end
