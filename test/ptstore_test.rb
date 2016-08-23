# coding: utf-8

require "test_helper"
require "ptstore"
require "tempfile"

class PTStore_Unit_Tests < Test::Unit::TestCase
  def setup
    tempfile = Tempfile.new(self.class.to_s)
    tempfile.close
    @db = PTStore.new(tempfile.path)

    @db.transaction do
      @db["Taro"] = {age: 22, lang: "Ruby", man: true, day: Time.now}
      @db["Hanako"] = {age: 23, lang: "Perl", man: false, day: Time.now}
      @db["Jirou"] = {age: 15, lang: "Smalltalk", man: true, day: Time.now}
      @db["Rika"] = {age: 4, lang: "Lisp", man: false, day: Time.now}
    end
  end

  def test_roots
    roots = nil
    @db.transaction do
      roots = @db.roots
    end
    %w{Taro Hanako Jirou Rika}.each do |n|
      assert(roots.include?(n))
    end
  end

  def test_settter_and_getter
    10.times do
      @db.transaction do
        @db["Hanako"][:age] += 1
      end
    end
    @db.transaction(true) do
      assert_equal(33, @db["Hanako"][:age])
    end
  end

  def test_transaction
    @db.transaction(true) do
      assert(@db.roots.include?("Taro"))

      assert_raise(PStore::Error) do
        @db["Ichiro"] = {}
      end
    end
  end

  def test_root_p
    @db.transaction(true) do
      assert(@db.root?("Taro"))
      assert(! @db.root?("Ichiro"))
    end
  end
end
