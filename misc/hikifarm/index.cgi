#!/usr/bin/env ruby
# Copyright (C) 2003, TADA Tadashi <sho@spc.gr.jp>
# Copyright (C) 2003, Kazuhiko <kazuhiko@fdiary.net>
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

#--- Default Settings -----------------------------------------------
ruby = '/usr/bin/env ruby'
hiki = ''
default_pages = "#{hiki}/text"
data_path = ''
cvsroot = nil
repos_type = nil
repos_root = nil
hikifarm_path = './'

title = ''
css = 'theme/hiki/hiki.css'

header = nil
footer = nil

cgi_name = 'index.cgi'

author = ''
mail = ''

eval( open( 'hikifarm.conf' ){|f|f.read.untaint} )
@ruby = ruby
@hiki = hiki
@default_pages = default_pages

# Support depracated configuration
if cvsroot then
   repos_type = 'cvs'
   repos_root = cvsroot
end

if repos_root =~ /:/ and repos_root.split(/:/)[1] != "local" then
  print <<ERROR
Content-Type: text/html; charset=EUC-JP

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="ja-JP">
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
   <meta name="generator" content="HikiFarm">
   <meta http-equiv="Content-Script-Type" content="text/javascript; charset=EUC-JP">
   <meta name="author" content="#{author}">
   <link rev="made" href="mailto:#{mail}">
   <meta http-equiv="content-style-type" content="text/css">
   <link rel="stylesheet" href="#{css}" title="tada" type="text/css" media="all">
   <title>#{title}</title>
</head>
<body>
<h1>Error</h1>
<p class="message">Hiki does not support remote repository now.
You should modify &quot;repos_root&quot; entry of &quot;hikifarm.conf&quot; file.</p>
</body>
</html>
ERROR
  exit 1
end

#--------------------------------------------------------------------

HIKIFARM_VERSION = '0.3.0.20040620'

def index( wiki )
<<-INDEX
#!#{@ruby}
hiki=''
eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
$:.unshift "\#{hiki}"
load "\#{hiki}/hiki.cgi"
INDEX
end

class WikiList
   attr_reader :name, :title, :mtime, :file
   def initialize(name, title, mtime, file)
      @name = name
      @title = title
      @mtime = mtime
      @file = file
   end
end

def conf( wiki )
<<CONF
hiki=''
eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
__my_wiki_name__ = '#{wiki}'
eval( File::open( "\#{hiki}/hiki.conf" ){|f| f.read.untaint} )
CONF
end

def rmdir( dir )
   dirlist = Dir::glob(dir + "**/").sort {
      |a,b| b.split('/').size <=> a.split('/').size
   }

   dirlist.each {|d|
      Dir::foreach(d) {|f|
         File::delete(d+f) if ! (/\.+$/ =~ f)
      }
      Dir::rmdir(d)
   }
end

# Null Repository Backend
class ReposDefault
   attr_reader :root, :data_path
   def initialize(root, data_path)
      @root = root
      @data_path = data_path
   end
   def setup()
   end
   def imported?( wiki )
      return true
   end
   def import( wiki )
   end
   def update( wiki )
   end
end

# CVS Repository Backend
class ReposCvs < ReposDefault
   def setup()
      oldpwd = Dir.pwd
      begin
         Dir.chdir( @data_path )
         system( "cvs -d #{@root} init > /dev/null 2>&1" )
         if not File.directory?(".CVSROOT") then
            system( "cvs -d #{@root} co -d .CVSROOT CVSROOT > /dev/null 2>&1" )
         end
         Dir.chdir( ".CVSROOT" )
         system( "cvs -d #{@root} update > /dev/null 2>&1" )
      ensure
         Dir.chdir( oldpwd.untaint )
      end
   end
   def imported?( wiki )
      return File.directory?( "#{@root}/#{wiki}" )
   end
   def import( wiki )
      oldpwd = Dir.pwd
      begin
         Dir.chdir( "#{@data_path}/#{wiki}/text" )
         system( "cvs -d #{@root} import -m 'Starting #{wiki}' #{wiki} #{wiki} start > /dev/null 2>&1" )
         Dir.chdir( '..' )
         system( "cvs -d #{@root} co -d text #{wiki} > /dev/null 2>&1" )
      ensure
         Dir.chdir( oldpwd.untaint )
      end
   end
   def update( wiki )
      oldpwd = Dir.pwd
      begin
         Dir.chdir( "#{@data_path}/#{wiki}/text" )
         system( "cvs -d #{@root} update > /dev/null 2>&1" )
      ensure
         Dir.chdir( oldpwd.untaint )
      end
   end
end

# Subversion Repository Backend
class ReposSvn < ReposDefault
   def setup()
      system( "svnadmin create #{@root} > /dev/null 2>&1" )
   end
   def imported?( wiki )
      s = ''
      open("|svn ls file://#{@root}/#{wiki}") do |f|
         s << (f.gets( nil ) ? $_ : '')
      end

      if s == "trunk/\n" then
         return true
      else
         return false
      end
   end
   def import( wiki )
      oldpwd = Dir.pwd
      begin
         Dir.chdir( "#{@data_path}/#{wiki}/text" )
         system( "svn import -m 'Starting #{wiki}' . file://#{@root}/#{wiki}/trunk > /dev/null 2>&1" )
         Dir.chdir( '..' )
         rmdir( 'text' )
         system( "svn checkout file://#{@root}/#{wiki}/trunk text > /dev/null 2>&1" )
         system( "svn propdel svn:mime-type -R text > /dev/null 2>&1" )
      ensure
         Dir.chdir( oldpwd )
      end
   end
   def update( wiki )
      oldpwd = Dir.pwd
      begin
         Dir.chdir( "#{@data_path}/#{wiki}/text" )
         system( "svn update > /dev/null 2>&1" )
      ensure
         Dir.chdir( oldpwd )
      end
   end
end

# Create repository backend
def create_repos(repos_type, repos_root, data_path)
   case repos_type
   when 'cvs'
      return ReposCvs.new(repos_root, data_path)
   when 'svn'
      return ReposSvn.new(repos_root, data_path)
   else
      return ReposDefault.new(repos_root, data_path)
   end
end

def create_wiki( wiki, hiki, cgi_name, data_path )
   Dir.mkdir( wiki.untaint )
   File.open( "#{wiki}/#{cgi_name}", 'w' ) do |f|
      f.puts( index( wiki ) )
      f.chmod( 0744 )
   end
   File::open( "#{wiki}/hikiconf.rb", 'w' ) do |f|
      f.puts( conf( wiki ) )
   end

   Dir.mkdir( "#{data_path}/#{wiki}" )
   Dir.mkdir( "#{data_path}/#{wiki}/text" )
   Dir.mkdir( "#{data_path}/#{wiki}/backup" )
   Dir.mkdir( "#{data_path}/#{wiki}/cache" )
   Dir["#{@default_pages}/*"].each do |file|
      next unless File.file?( file.untaint )
      File.open( file ) do |i|
         File.open( "#{data_path}/#{wiki}/text/#{File.basename file}", 'w' ) do |o|
            o.write( i.read )
         end
      end
   end
   @repos.import( wiki )
end

def body( data_path )
   r = "<table>\n"
   r << %Q|<tr><th>Wiki の名前</th><th>タイトル</th><th>最終更新時刻</th></tr>|
   wikilist = []
   Dir['*'].each do |wiki|
      next unless FileTest::directory?( wiki.untaint )
      next if FileTest::symlink?( wiki )
      next unless FileTest::file?( "#{wiki}/hikiconf.rb" )
      if not @repos.imported?( wiki ) then
         @repos.import( wiki )
      end
      @repos.update( wiki )
      title = wiki
      mtime = nil
      file = ''
      begin
         File::open( "#{data_path}/#{wiki}/hiki.conf" ) do |conf|
            if /^@site_name\s*=\s*(".*")\s*$/ =~ conf.read then
               title = eval($1.untaint)
            end
         end
      rescue
      	 title = "#{wiki}'s Wiki"
      end
      Dir["#{data_path}/#{wiki}/text/*"].sort{ |a,b| File.mtime(a.untaint) <=> File.mtime(b.untaint) }.reverse.each do |f|
         next if File.basename(f) == "CVS" || !File.size?(f)
	 mtime = File.mtime(f)
	 file = f.gsub(/.*\//, '')
	 break
      end
      wikilist.push( WikiList.new(wiki, title, mtime, file) ) if mtime
   end
   wikilist = wikilist.sort{ |a,b| a.mtime <=> b.mtime }.reverse
   wikilist.each do |wiki|
      page = CGI.escapeHTML(CGI.unescape(wiki.file))
      r << %Q|<tr>|
      r << %Q|<td><a href="#{wiki.name}/">#{wiki.name}</a></td>|
      r << %Q|<td>#{CGI::escapeHTML(wiki.title)}</td>|
      r << %Q|<td>#{wiki.mtime.strftime("%Y/%m/%d %H:%M:%S")}|
      r << %Q| (<a href="#{wiki.name}/?#{wiki.file}">#{page}</a>)</td></tr>\n|
   end
   @head['Last-Modified'] = CGI::rfc1123_date( wikilist[0].mtime ) unless wikilist.empty?
r << "</table>\n"
end

def form
   <<-FORM
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
   FORM
end

def error( msg )
   if msg then
      %Q|<p class="message">#{msg}</p>\n|
   else
      ''
   end
end

#--- main -----------------------------------------------------------

require 'cgi'

cgi = CGI::new
msg = nil
@repos = create_repos(repos_type, repos_root, data_path)

@repos.setup()

if cgi.params['wiki'][0] and cgi.params['wiki'][0].length > 0 then
   begin
      wiki = cgi.params['wiki'][0]
      raise '英数字のみ指定できます' unless /\A[a-zA-Z0-9]+\z/ =~ wiki
      create_wiki( wiki, hiki, cgi_name, data_path )
   rescue
      msg = %Q|#{$!.to_s}\n#{$@.join("\n")}|
   end
end

@head = {
   'type' => 'text/html; charset=EUC-JP'
}

@body = body( data_path )
header_content = File::open( header ) do |f| f.read end if header
footer_content = File::open( footer ) do |f| f.read end if footer
print cgi.header( @head )
print <<PAGE
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="ja-JP">
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
   <meta name="generator" content="HikiFarm">
   <meta http-equiv="Content-Script-Type" content="text/javascript; charset=EUC-JP">
   <meta name="author" content="#{author}">
   <link rev="made" href="mailto:#{mail}">
   <meta http-equiv="content-style-type" content="text/css">
   <link rel="stylesheet" href="#{css}" title="tada" type="text/css" media="all">
   <title>#{title}</title>
</head>
<body>
#{error( msg )}
<h1>#{title}</h1>
   #{header_content if header_content}

   <hr class="sep">

   <div class="day">
      <h2><span class="title">現在運用中の Wiki サイト</span></h2>
      <div class="body"><div class="section">
      #{@body}
      </div></div>
   </div>

   <hr class="sep">

   <div class="update day">
      <h2><span class="title">新しい Wiki サイトの作成</span></h2>
      <div class="form">
         <form class="update" method="post" action="#{hikifarm_path}">
         #{form}
         </form>
      </div>
   </div>
   <hr class="sep">
   #{footer_content if footer_content}
   <div class="footer">
      Generated by <a href="http://www.namaraii.com/hiki/?HikiFarm">HikiFarm</a> version #{HIKIFARM_VERSION}<br>
      Powered by <a href="http://www.ruby-lang.org/">Ruby</a> version #{RUBY_VERSION}#{if /ruby/i =~ ENV['GATEWAY_INTERFACE'] then ' with <a href="http://www.modruby.net/">mod_ruby</a>' end}
   </div>
</body>
</html>
PAGE
