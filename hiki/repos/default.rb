# $Id: default.rb,v 1.3 2005-06-13 05:49:19 fdiary Exp $
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

    def commit(page, log = nil)
    end

    def delete(page, log = nil)
    end

    private

    def default_msg
      "#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}"
    end
  end
end
