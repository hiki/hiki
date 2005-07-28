# $Id: xmlrpc.rb,v 1.2 2005-07-28 15:05:30 yanagita Exp $

require 'xmlrpc/server'
require 'hiki/plugin'

module Hiki
  class XMLRPCServer
    def initialize(xmlrpc_enabled)
      if defined?(MOD_RUBY)
        @server = XMLRPC::ModRubyServer.new
      else
        @server = XMLRPC::CGIServer.new
      end

      init_handler if xmlrpc_enabled
    end

    def serve
      @server.serve
    end

    private
    def init_handler
      @server.add_handler('wiki.getPage') do |page|
        conf = Hiki::Config::new
        db = Hiki::HikiDB::new( conf )
        begin
          ret = db.load( page ) || ''
        rescue
          STDERR.puts $!, $@.inspect
          ret = false
        end
        ret
      end

      @server.add_handler('wiki.putPage') do |page, content, attributes|
        attributes ||= {}
        conf = Hiki::Config::new
        cgi = CGI::new
        cgi.params['c'] = ['save']
        cgi.params['p'] = [page]
        db = Hiki::HikiDB::new( conf )
        begin
          options = conf.options || Hash::new( '' )
          options['page'] = page
          options['cgi']  = cgi
          options['db']  = db
          options['params'] = Hash::new( [] )
          plugin = Hiki::Plugin::new( options, conf )
          plugin.login( attributes['name'], attributes['password'] )

          raise "can't edit this page." unless plugin.editable?( page )

          md5hex = db.md5hex( page )
          plugin.save( page, content.gsub(/\r/, ''), md5hex )
          keyword = attributes['keyword'] || []
          title = attributes['title']
          attr = [[:keyword, keyword.uniq], [:editor, plugin.user]]
          attr << [:title, title] if title
          db.set_attribute(page, attr)
          if plugin.admin? && attributes.has_key?( 'freeze' )
            db.freeze_page( page, attributes['freeze'] ? true : false)
          end
          ret = true
        rescue
          STDERR.puts $!, $@.inspect
          ret = false
        end
        ret
      end

    end
  end
end
