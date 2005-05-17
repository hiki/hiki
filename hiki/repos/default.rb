# $Id: default.rb,v 1.2 2005-05-17 05:33:08 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

# Null Repository Backend

module Hiki
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
     def commit( page )
     end
     def delete( page )
     end
  end
end
