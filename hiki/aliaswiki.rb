# $Id: aliaswiki.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

module Hiki
  class AliasWiki
    require 'hiki/util'
    
    ALIASWIKI_NAME_RE =  /\[\[(.+):(.+)\]\]/

    attr_reader :aliaswiki_names
    
    def initialize(db)
      @db = db
      @aliaswiki_names = Hash::new
      load_aliaswiki_names
    end

    def aliaswiki(name)
      @aliaswiki_names.has_key?(name) ? @aliaswiki_names[name] : name
    end

    def original_name(alias_name)
      orig = @aliaswiki_names.index(alias_name)
      orig ? orig : alias_name
    end

    private
    def load_aliaswiki_names
      n = @db.load( $aliaswiki_name ) || ''
      n.scan( ALIASWIKI_NAME_RE ) do |i|
        @aliaswiki_names[i[0]] = i[1]
      end
    end
  end
end
