# coding: utf-8
# $Id: ptstore.rb,v 1.12 2006-08-07 02:10:27 fdiary Exp $
#
# ptstore.rb
#   based on pstore.rb contained in Ruby 1.8.2
#
# How to use:
#
# db = PTStore.new("/tmp/foo")
# db.transaction do
#   p db.roots
#   ary = db["root"] = [1,2,3,4]
#   ary[0] = [1,1.5]
# end

# db.transaction do
#   p db["root"]
# end

require 'pstore'
require "hiki/db/tmarshal"


class PTStore < PStore
  def dump(table)
    TMarshal.dump(table)
  end

  def load(content)
    TMarshal.load(content)
  end

  def load_file(file)
    TMarshal.load(file)
  end
end