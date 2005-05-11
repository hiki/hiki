#!/usr/bin/env ruby

HIKIFARM_VERSION = '0.4.0.20050511'

class HikifarmConfig
  attr_reader :ruby, :hiki, :hikifarm_path, :default_pages, :data_path, :repos_type, :repos_root
  attr_reader :title, :css, :author, :mail, :cgi_name, :header, :footer, :cgi
  
  def initialize
    load
    require 'cgi'
    @cgi = CGI.new
  end

  def load
    # デフォルト設定
    # 前もって定義してないと eval しても残らない
    ruby = '/usr/bin/env ruby'
    hiki = ''
    hikifarm_path = ''
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

    eval(File.read('hikifarm.conf').untaint)

    @ruby = ruby
    @hiki = hiki
    @hikifarm_path = hikifarm_path
    @default_pages = default_pages
    @data_path = data_path

    @repos_type = repos_type || 'default'
    @repos_root = repos_root

    @title = title
    @css = css
    @author = author
    @mail = mail
    @header = header
    @footer = footer
    @cgi_name = cgi_name

    # Support depracated configuration
    if cvsroot then
      @repos_type = 'cvs'
      @repos_root = cvsroot
    end


    if @repos_root =~ /:/ and @repos_root.split(/:/)[1] != "local"
      msg = "Hiki does not support remote repository now." + 
        "You should modify &quot;repos_root&quot; entry of &quot;hikifarm.conf&quot; file."
      page = ErrorPage.new(@author, @mail, @css, @title, msg)
      body = page.to_s
      print @cgi.header(page.headings)
      print body
      exit 1
    end

  end
end



class Wiki
  attr_reader :name, :title, :mtime, :last_modified_page, :pages_num
  def initialize(name, data_path)
    @name = name
    @pages_num = 0

    begin
      File.readlines("#{data_path}/#{name}/hiki.conf").each do |line|
        if line =~ /^@?site_name\s*=\s*(".*")\s*$/
          @title = eval($1.untaint)
        end
      end
    rescue
      @title = "#{name}'s Wiki"
    end

    pages = Dir["#{data_path}/#{name}/text/*"]
    pages.delete_if{|f| File.basename(f) == 'CVS' or File.basename(f) == '.svn' or File.size?(f.untaint).nil?}
    pages = pages.sort_by{|f| File.mtime(f)}
    @last_modified_page = File.basename(pages[-1])
    @mtime = File.mtime(pages[-1])
    @pages_num = pages.size
  end
end

class Hikifarm
  attr_reader :wikilist
  
  def initialize(farm_pub_path, ruby, repos_type, repos_root, data_path)
    require "hiki/repos/#{repos_type}"
    @repos = Hiki::const_get("Repos#{repos_type.capitalize}").new(repos_root, data_path)
    @ruby = ruby
    @wikilist = []
    @farm_pub_path = farm_pub_path

    Dir["#{farm_pub_path}/*"].each do |wiki|
      wiki.untaint
      next if not FileTest.directory?(wiki)
      next if FileTest.symlink?(wiki)
      next if not FileTest.file?("#{wiki}/hikiconf.rb")

      begin
        @wikilist << Wiki.new(File.basename(wiki), data_path)
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

  def create_wiki(name, hiki, cgi_name, data_path, default_pages_path)
    Dir.mkdir("#{@farm_pub_path}/#{name.untaint}")

    File.open("#{@farm_pub_path}/#{name}/#{cgi_name}", 'w') do |f|
      f.puts(index(name, hiki)) # fix me
      f.chmod(0744)
    end

    File.open("#{@farm_pub_path}/#{name}/hikiconf.rb", 'w') do |f|
      f.puts(conf(name, hiki)) # fix me
    end

    Dir.mkdir("#{data_path}/#{name}")
    Dir.mkdir("#{data_path}/#{name}/text")
    Dir.mkdir("#{data_path}/#{name}/backup")
    Dir.mkdir("#{data_path}/#{name}/cache")
    require 'fileutils'
    Dir["#{default_pages_path}/*"].each do |f|
      f.untaint
      FileUtils.cp(f, "#{data_path}/#{name}/text/#{File.basename(f)}") if File.file?(f)
    end

    @repos.import(name)
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


end



class ErbPage
  attr_reader :headings

  def initialize
    @headings = {
      'type' => 'text/html; charset=EUC-JP'
    }
  end

  def to_s
    require 'erb'
    erb = ERB.new(template)
    erb.result
  end
end

class ErrorPage < ErbPage
  def initialize(author, mail, css, title, msg)
    super()
    @author = author
    @mail = mail
    @css = css
    @title = title
    @msg = msg
  end

  private
  def template
<<ERROR
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="ja-JP">
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
   <meta name="generator" content="HikiFarm">
   <meta http-equiv="Content-Script-Type" content="text/javascript; charset=EUC-JP">
   <meta name="author" content="#{@author}">
   <link rev="made" href="mailto:#{@mail}">
   <meta http-equiv="content-style-type" content="text/css">
   <link rel="stylesheet" href="#{@css}" title="tada" type="text/css" media="all">
   <title>#{@title}</title>
</head>
<body>
<h1>Error</h1>
<p class="message">#{@msg}</p>
</body>
</html>
ERROR
  end
end

class HikifarmIndexPage < ErbPage
  def initialize(farm, hikifarm_path, author, mail, css, title, header_file, footer_file, msg)
    super()
    @farm = farm
    @hikifarm_path = hikifarm_path
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
  
  def template
<<PAGE
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="ja-JP">
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
   <meta name="generator" content="HikiFarm">
   <meta http-equiv="Content-Script-Type" content="text/javascript; charset=EUC-JP">
   <meta name="author" content="#{@author}">
   <link rev="made" href="mailto:#{@mail}">
   <meta http-equiv="content-style-type" content="text/css">
   <link rel="stylesheet" href="#{@css}" title="tada" type="text/css" media="all">
   <title>#{@title}</title>
</head>
<body>
#{error_msg(@msg)}
<h1>#{@title}</h1>
   #{@header_content if @header_content}

   <hr class="sep">

   <div class="day">
      <h2><span class="title">現在運用中の Wiki サイト</span></h2>
      <div class="body"><div class="section">
      #{wikilist_table}
      </div></div>
   </div>

   <hr class="sep">

   <div class="update day">
     <h2><span class="title">新しい Wiki サイトの作成</span></h2>
     <div class="form">
       <form class="update" method="post" action="#{@hikifarm_path}">
         <div>
           作成したい Wiki サイトの名称を指定します。
           これは URL に含まれるので、できるだけ短く、
           かつ Wiki の目的をよく表現したものが良いでしょう。
         </div>
         <div class="field title">
           Wiki の名前 (英数字のみ):
           <input class="field" name="wiki" size="20" value="">
           <input class="submit" type="submit" value="作成">
         </div>
       </form>
     </div>
   </div>
   <hr class="sep">
   #{@footer_content if @footer_content}
   <div class="footer">
     #{footer}
   </div>
</body>
</html>
PAGE
  end

  def wikilist_table
    r = ''
    r = "<p>全 #{@farm.wikis_num} Wiki / #{@farm.pages_num} ページ (* は差分へのリンク)</p>\n"
    r << "<table>\n"
    r << %Q!<tr><th>Wiki の名前</th><th>タイトル</th><th>最終更新時刻</th></tr>!
    wikilist = @farm.wikilist.sort{ |a,b| a.mtime <=> b.mtime }.reverse
    wikilist.each do |wiki|
      page = CGI.escapeHTML(CGI.unescape(wiki.last_modified_page))
      r << %Q!<tr>!
      r << %Q!<td><a href="#{wiki.name}/">#{wiki.name}</a></td>!
      r << %Q!<td>#{CGI::escapeHTML(wiki.title)}</td>!
      r << %Q!<td>#{wiki.mtime.strftime("%Y/%m/%d %H:%M")}!
      r << %Q! <a href="#{wiki.name}/?c=diff;p=#{wiki.last_modified_page}">*</a>\n!
      r << %Q! <a href="#{wiki.name}/?#{wiki.last_modified_page}">#{page}</a></td></tr>\n!
    end
    @headings['Last-Modified'] = CGI::rfc1123_date( wikilist[0].mtime ) unless wikilist.empty?
    r << "</table>\n"
  end

  def footer
    %Q!Generated by <a href="http://www.namaraii.com/hiki/?HikiFarm">HikiFarm</a> version ! + HIKIFARM_VERSION + '<br>' +
      %Q!Powered by <a href="http://www.ruby-lang.org/">Ruby</a> version ! + RUBY_VERSION +
      (/ruby/i =~ ENV['GATEWAY_INTERFACE']  ? ' with <a href="http://www.modruby.net/">mod_ruby</a>' : '')
  end
end

class App
  def initialize(conf)
    @conf = conf
    @farm = Hikifarm.new(File.dirname(__FILE__), @conf.ruby, @conf.repos_type, @conf.repos_root, @conf.data_path)
    @cgi = conf.cgi
  end

  def run
    msg = nil
    if /post/i =~ @cgi.request_method and @cgi.params['wiki'][0] and @cgi.params['wiki'][0].length > 0
      begin
        name = @cgi.params['wiki'][0]
        raise '英数字のみ指定できます' if /\A[a-zA-Z0-9]+\z/ !~ name
        @farm.create_wiki(name, @conf.hiki, @conf.cgi_name, @conf.data_path, @conf.default_pages)

        require 'hiki/util'
        Hiki::Util.module_eval('module_function :redirect')
        Hiki::Util.redirect(@cgi, @conf.cgi_name)
        exit
      rescue
        msg = %Q|#{$!.to_s}\n#{$@.join("\n")}|
      end
    end
    page = HikifarmIndexPage.new(@farm, @conf.hikifarm_path, @conf.author, @conf.mail, @conf.css, @conf.title,
                                 @conf.header, @conf.footer, msg)
    body = page.to_s
    print @cgi.header(page.headings)
    print body
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
