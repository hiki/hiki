# $Id: xmlrpc.rb,v 1.6 2005-09-29 03:01:15 fdiary Exp $

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
        page = utf8_to_euc( page )
        conf = Hiki::Config::new
        db = Hiki::HikiDB::new( conf )
        begin
          ret = XMLRPC::Base64.new( euc_to_utf8( db.load( page ) || '' ) )
        rescue
          STDERR.puts $!, $@.inspect
          ret = false
        end
        ret
      end

      @server.add_handler('wiki.getPageInfo') do |page|
        page = utf8_to_euc( page )
        conf = Hiki::Config::new
        db = Hiki::HikiDB::new( conf )
        begin
          title = db.get_attribute( page, :title )
          title = page if title.nil? || title.empty?
          ret = {
            'title' => XMLRPC::Base64.new( euc_to_utf8( title ) ),
            'keyword' => db.get_attribute( page, :keyword ).collect { |k| XMLRPC::Base64.new( euc_to_utf8( k ) ) },
            'lastModified' => db.get_attribute( page, :last_modified ).getutc,
            'author' => XMLRPC::Base64.new( db.get_attribute( page, :editor ) || '' )
          }
        rescue
          STDERR.puts $!, $@.inspect
          ret = false
        end
        ret
      end

      @server.add_handler('wiki.putPage') do |page, content, attributes|
        page = utf8_to_euc( page )
        content = utf8_to_euc( content )
        attributes ||= {}
        attributes.each_pair { |k, v| v.replace( utf8_to_euc( v ) ) }
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
          plugin.save( page, content.gsub( /\r/, '' ), md5hex )
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

      @server.add_handler('wiki.getAllPages') do
        conf = Hiki::Config::new
        db = Hiki::HikiDB::new( conf )
        begin
          ret = db.pages.collect{|p| XMLRPC::Base64.new( euc_to_utf8( p ) )}
        rescue
          STDERR.puts $!, $@.inspect
          ret = false
        end
        ret
      end

    end
  end
end
