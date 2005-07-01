#!/usr/bin/env ruby

BEGIN { $defout.binmode }

$SAFE     = 1
$KCODE    = 'e'

if FileTest::symlink?( __FILE__ ) then
  org_path = File::dirname( File::readlink( __FILE__ ) )
else
  org_path = File::dirname( __FILE__ )
end
$:.unshift( org_path.untaint, "#{org_path.untaint}/hiki" )

require 'xmlrpc/server'
require 'hiki/config'
require 'hiki/plugin'

if defined?(MOD_RUBY)
  server = XMLRPC::ModRubyServer.new
else
  server = XMLRPC::CGIServer.new
end

server.add_handler('wiki.getPage') do |page|
  @conf = Hiki::Config::new
  @db = Hiki::HikiDB::new( @conf )
  begin
    ret = @db.load( page ) || ''
  rescue
    STDERR.puts $!, $@.inspect
    ret = false
  end
  ret
end

server.add_handler('wiki.putPage') do |page, content, attributes|
  @conf = Hiki::Config::new
  @cgi = CGI::new
  @cgi.params['c'] = ['save']
  @cgi.params['p'] = [page]
  @db = Hiki::HikiDB::new( @conf )
  begin
    options = @conf.options || Hash::new( '' )
    options['page'] = page
    options['cgi']  = @cgi
    options['db']  = @db
    options['params'] = Hash::new( [] )
    @plugin = Hiki::Plugin::new( options, @conf )

    pass_check = false
    if p = attributes['password']
      pass_check = true if @conf.password.size == 0 || p.crypt( @conf.password ) == @conf.password
    end

    if (@db.is_frozen?( page ) || @conf.options['freeze']) && !pass_check
      raise "can't edit a frozen page."
    end

    md5hex = @db.md5hex( page )
    @plugin.save( page, content.gsub(/\r/, ''), md5hex )
    keyword = attributes['keyword'] || []
    title = attributes['title'] || page
    @db.set_attribute(page, [[:keyword, keyword.uniq], [:title, title]])
    if pass_check
      @db.freeze_page( page, attributes['freeze'] ? true : false)
    end
    ret = true
  rescue
    STDERR.puts $!, $@.inspect
    ret = false
  end
  ret
end

server.serve
