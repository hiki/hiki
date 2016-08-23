
require "xmlrpc/server"
require "hiki/plugin"

module Hiki
  module XMLRPCHandler
    module_function

    def init_handler(server, conf, request)
      server.add_handler("wiki.getPage") do |page|
        db = conf.database
        ret = db.load(page)
        unless ret
          raise XMLRPC::FaultException.new(1, "No such page was found.")
        end
        XMLRPC::Base64.new(ret)
      end

      server.add_handler("wiki.getPageInfo") do |page|
        db = conf.database
        title = db.get_attribute(page, :title)
        title = page if title.nil? || title.empty?
        {
          "title" => XMLRPC::Base64.new(title),
          "keyword" => db.get_attribute(page, :keyword).collect {|k| XMLRPC::Base64.new(k) },
          "md5hex" => db.md5hex(page),
          "lastModified" => db.get_attribute(page, :last_modified).getutc,
          "author" => XMLRPC::Base64.new(db.get_attribute(page, :editor) || "")
        }
      end

      server.add_handler("wiki.putPage") do |page, content, attributes|
        attributes ||= {}
        attributes.each_pair {|k, v|
          case v
          when String
            v.replace(v)
          when Array
            v.map!{|s| s.replace(s) }
          end
        }
        request.params["c"] = "save"
        request.params["p"] = page
        db = conf.database
        options = conf.options || Hash.new("")
        options["page"]     = page
        options["request"]  = request
        options["cgi"]      = request # for backward compatibility
        options["db"]       = db
        options["params"]   = Hash.new("")
        plugin = Hiki::Plugin.new(options, conf)
        plugin.login(attributes["name"], attributes["password"])
        Hiki::Filter.init(conf, request, plugin, db)

        unless plugin.editable?(page)
          raise XMLRPC::FaultException.new(10, "can't edit this page.")
        end

        md5hex = attributes["md5hex"] || db.md5hex(page)
        update_timestamp = !attributes["minoredit"]
        unless plugin.save(page, content.gsub(/\r/, ""), md5hex, update_timestamp)
          raise XMLRPC::FaultException.new(11, "save failed.")
        end
        keyword = attributes["keyword"] || db.get_attribute(page, :keyword)
        title = attributes["title"]
        attr = [[:keyword, keyword.uniq], [:editor, plugin.user]]
        attr << [:title, title] if title
        db.set_attribute(page, attr)
        if plugin.admin? && attributes.has_key?("freeze")
          db.freeze_page(page, attributes["freeze"] ? true : false)
        end
        true
      end

      server.add_handler("wiki.getAllPages") do
        db = conf.database
        db.pages.collect{|p| XMLRPC::Base64.new(p)}
      end

      # add_multicall
      # add_introspection
    end
  end

  class XMLRPCServer
    include XMLRPCHandler

    def initialize(conf, request)
      return unless conf.xmlrpc_enabled

      case
      when Object.const_defined?(:Rack)
        require "hiki/xmlrpc/rackserver.rb"
        @server = XMLRPC::RackServer.new(request)
      when Object.const_defined?(:MOD_RUBY)
        @server = XMLRPC::ModRubyServer.new
      when Object.const_defined?(:CGI)
        @server = XMLRPC::CGIServer.new
      else
        raise "must not happen!"
      end

      init_handler(@server, conf, request)
    end

    def serve
      @server.serve
    end
  end
end
