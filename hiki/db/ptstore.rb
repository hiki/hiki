# $Id: ptstore.rb,v 1.11 2006-08-04 15:10:09 fdiary Exp $
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

require "fileutils"
require "digest/md5"
require "hiki/db/tmarshal"

require 'pstore'

class PTStore < PStore
  def transaction(read_only = false)
    raise PStore::Error, "nested transaction" if @transaction
    begin
      @rdonly = read_only
      @abort = false
      @transaction = true
      value = nil
      new_file = @filename + ".new"

      content = nil
      unless read_only
        file = File.open(@filename, File::RDWR | File::CREAT)
        file.binmode
        file.flock(File::LOCK_EX)
        commit_new(file) if FileTest.exist?(new_file)
        content = file.read()
      else
        if @table_cache.nil?
          begin
            file = File.open(@filename, File::RDONLY)
            file.binmode
            file.flock(File::LOCK_SH)
            content = (File.read(new_file) rescue file.read())
          rescue Errno::ENOENT
            content = ""
          end
        end
      end

      case content
      when nil # use cache
        @table = @table_cache.dup
      when ""  # empty data
	@table = {}
        @table_cache = @table.dup
      else
	@table = load(content)
        @table_cache = @table.dup
        if !read_only
          size = content.size
          md5 = Digest::MD5.digest(content)
        end
      end
      content = nil		# unreference huge data

      begin
	catch(:pstore_abort_transaction) do
	  value = yield(self)
	end
      rescue Exception
	@abort = true
	raise
      ensure
	if !read_only and !@abort
          tmp_file = @filename + ".tmp"
	  content = dump(@table)
	  if !md5 || size != content.size || md5 != Digest::MD5.digest(content)
            File.open(tmp_file, "w") {|t|
              t.binmode
              t.write(content)
            }
            File.rename(tmp_file, new_file)
            commit_new(file)
          end
          content = nil		# unreference huge data
	end
      end
    ensure
      unless read_only
        @table_cache = @table
      end
      @table = nil
      @transaction = false
      file.close if file
    end
    value
  end

  def close_cache
    # do nothing
  end

  def dump(table)
  $stderr.puts 'dump'
    TMarshal::dump(table)
  end

  def load(content)
  $stderr.puts 'load'
    TMarshal::load(content)
  end

  def load_file(file)
    TMarshal::load(file)
  end
end

if __FILE__ == $0
  db = PTStore.new("/tmp/foo")

  db.transaction do
    db['Taro'] = {:age => 22, :lang => 'Ruby', :man => true, :day => Time.now}
    db['Hanako'] = {:age => 23, :lang => 'Perl', :man => false, :day => Time.now}
    db['Jirou'] = {:age => 15, :lang => 'Smalltalk', :man => true, :day => Time.now}
    db['Rika'] = {:age => 4, :lang => 'Lisp', :man => false, :day => Time.now}
  end

  db.transaction do
    db.roots.each do |k|
      p k, db[k]
    end
  end

  10.times do
    db.transaction do
      db['Hanako'][:age] += 1
      p db['Hanako'][:age]
    end
  end

  db.transaction(true) do
    db.roots.each do |k|
      p k, db[k]
    end
  end

#  db.transaction do
#    p db.root? ('Taro')
#    p db.root? ('Hitoshi')
#  end
end
