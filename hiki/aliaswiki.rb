# $Id: aliaswiki.rb,v 1.5 2005-06-15 03:10:16 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

module Hiki
  class AliasWiki
    require 'hiki/util'
    
    ALIASWIKI_NAME_RE =  /\[\[(.+):(.+)\]\]/

    attr_reader :aliaswiki_names
    
    def initialize(str)
      @aliaswiki_names = Hash::new
      (str || '').scan( ALIASWIKI_NAME_RE ) do |i|
        @aliaswiki_names[i[0]] = i[1]
      end
    end

    def aliaswiki(name)
      @aliaswiki_names.has_key?(name) ? @aliaswiki_names[name] : name
    end

    def original_name(alias_name)
      orig = @aliaswiki_names.key(alias_name)
      orig ? orig : alias_name
    end
  end
end
