# $Id: aliaswiki.rb,v 1.4 2005-01-14 01:39:46 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

module Hiki
  class AliasWiki
    require 'hiki/util'
    
    ALIASWIKI_NAME_RE =  /\[\[(.+):(.+)\]\]/

    attr_reader :aliaswiki_names
    
    def initialize(db, conf)
      @db = db
      @conf = conf
      @aliaswiki_names = Hash::new
      load_aliaswiki_names
    end

    def aliaswiki(name)
      @aliaswiki_names.has_key?(name) ? @aliaswiki_names[name] : name
    end

    def original_name(alias_name)
      orig = @aliaswiki_names.key(alias_name)
      orig ? orig : alias_name
    end

    private
    def load_aliaswiki_names
      n = @db.load( @conf.aliaswiki_name ) || ''
      n.scan( ALIASWIKI_NAME_RE ) do |i|
        @aliaswiki_names[i[0]] = i[1]
      end
    end
  end
end
