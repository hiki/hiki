#!/usr/local/opt/ruby/bin/ruby
#!/usr/bin/env ruby
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
$LOAD_PATH.unshift "lib"

BEGIN { $stdout.binmode }

# FIXME encoding can be different (eg. iso-8859-1 in
# hikiconf.rb.sample.en).
Encoding.default_external = 'utf-8'

begin
  if FileTest::symlink?( __FILE__ )
    org_path = File.dirname( File.expand_path( File.readlink( __FILE__ ) ) )
  else
    org_path = File.dirname( File.expand_path( __FILE__ ) )
  end
  $:.unshift( org_path.untaint, "#{org_path.untaint}/hiki" )
  $:.delete(".") if File.writable?(".")

  require 'hiki/config'
  conf = Hiki::Config.new
  request = Hiki::Request.new(ENV)

  if ENV['CONTENT_TYPE'] =~ %r!\Atext/xml!i and ENV['REQUEST_METHOD'] =~ /\APOST\z/i
    require 'hiki/xmlrpc'
    server = Hiki::XMLRPCServer.new(conf, request)
    server.serve
  else
    # FIXME encoding can be different (eg. iso-8859-1 in
    # hikiconf.rb.sample.en).
    #cgi = CGI.new(:accept_charset=>"euc-jp")

    response = nil
    db = conf.database
    db.open_db {
      cmd = Hiki::Command.new(request, db, conf)
      response = cmd.dispatch
    }
    print response.header
    print response.body
  end
rescue Exception => err
  if request
    print request.cgi.header( 'status' => '500 Internal Server Error', 'type' => 'text/html' )
  else
    print "Status: 500 Internal Server Error\n"
    print "Content-Type: text/html\n\n"
  end

  require 'cgi'
  puts '<html><head><title>Hiki Error</title></head><body>'
  puts '<h1>Hiki Error</h1>'
  puts '<pre>'
  puts CGI.escapeHTML( "#{err} (#{err.class})\n" )
  puts CGI.escapeHTML( err.backtrace.join( "\n" ) )
  puts '</pre>'
  puts "<div>#{' ' * 500}</div>"
  puts '</body></html>'
end
