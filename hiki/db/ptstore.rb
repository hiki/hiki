# $Id: ptstore.rb,v 1.9 2006-02-04 12:20:18 znz Exp $
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

class PTStore
  class Error < StandardError
  end

  def initialize(file)
    dir = File::dirname(file)
    unless File::directory? dir
      raise PTStore::Error, format("directory %s does not exist", dir)
    end
    if File::exist? file and not File::readable? file
      raise PTStore::Error, format("file %s not readable", file)
    end
    @transaction = false
    @filename = file
    @abort = false
  end

  def in_transaction
    raise PTStore::Error, "not in transaction" unless @transaction
  end
  def in_transaction_wr()
    in_transaction()
    raise PStore::Error, "in read-only transaction" if @rdonly
  end
  private :in_transaction, :in_transaction_wr

  def [](name)
    in_transaction
    @table[name]
  end
  def fetch(name, default=PTStore::Error)
    unless @table.key? name
      if default==PTStore::Error
        raise PTStore::Error, format("undefined root name `%s'", name)
      else
        default
      end
    end
    self[name]
  end
  def []=(name, value)
    in_transaction_wr()
    @table[name] = value
  end
  
  def delete(name)
    in_transaction_wr()
    @table.delete name
  end

  def roots
    in_transaction
    @table.keys
  end
  def root?(name)
    in_transaction
    @table.key? name
  end
  def path
    @filename
  end

  def commit
    in_transaction
    @abort = false
    throw :ptstore_abort_transaction
  end
  def abort
    in_transaction
    @abort = true
    throw :ptstore_abort_transaction
  end

  def close_cache
    @file_cache.close if @file_cache
  end

  def transaction(read_only=false)
    raise PTStore::Error, "nested transaction" if @transaction
    begin
      if !read_only
        @table_cache = nil
        @file_cache.close if @file_cache
        @file_cache = nil
      end

      @rdonly = read_only
      @abort = false
      @transaction = true
      value = nil

      if @file_cache
        file = @file_cache
        file.flock(File::LOCK_SH)
        @table = @table_cache
      else
        new_file = @filename + ".new"

        content = nil
        unless read_only
          file = File.open(@filename, File::RDWR | File::CREAT)
          file.binmode
          file.flock(File::LOCK_EX)
          commit_new(file) if FileTest.exist?(new_file)
          content = file.read()
        else
          begin
            file = File.open(@filename, File::RDONLY)
            file.binmode
            file.flock(File::LOCK_SH)
            content = (File.read(new_file) rescue file.read())
          rescue Errno::ENOENT
            content = ""
          end
        end

        if content != ""
          @table = load(content)
          if !read_only
            size = content.size
            md5 = Digest::MD5.digest(content)
          end
        else
          @table = {}
        end
        content = nil                # unreference huge data
      end

      begin
        catch(:ptstore_abort_transaction) do
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
          content = nil                # unreference huge data
        end
      end
    ensure
      if file
        file.flock(File::LOCK_UN)
        if read_only
          @table_cache = @table
          @file_cache = file
        else
          file.close
        end
      end

      @table = nil
      @transaction = false
    end
    value
  end

  def dump(table)
    TMarshal::dump(table)
  end

  def load(content)
    TMarshal::load(content)
  end

  def load_file(file)
    TMarshal::load(file)
  end

  private
  def commit_new(f)
    f.truncate(0)
    f.rewind
    new_file = @filename + ".new"
    File.open(new_file) do |nf|
      nf.binmode
      FileUtils.copy_stream(nf, f)
    end
    File.unlink(new_file)
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
