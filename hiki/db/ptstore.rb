# $Id: ptstore.rb,v 1.1.1.1 2003-02-22 04:39:31 hitoshi Exp $
#
# ptstore.rb
#   converts pstore.rb contained in Ruby 1.8.0 Preview 1.
#
# How to use:
#
# db = TStore.new("/tmp/foo")
# db.transaction do
#   p db.roots
#   ary = db["root"] = [1,2,3,4]
#   ary[0] = [1,1.5]
# end
# db.transaction do
#   p db["root"]
# end


require "ftools"
require "digest/md5"
require "hiki/db/tmarshal"

class PTStore
  include TMarshal
  class Error < StandardError
  end

  def initialize(file)
    dir = File::dirname(file)
    unless File::directory? dir
      raise PTStore::Error, format("directory %s does not exist", dir)
    end
    unless File::writable? dir
      raise PTStore::Error, format("directory %s not writable", dir)
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
  private :in_transaction

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
    in_transaction
    @table[name] = value
  end
  
  def delete(name)
    in_transaction
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

  def transaction(read_only=false)
    raise PTStore::Error, "nested transaction" if @transaction
    begin
      @transaction = true
      value = nil
      backup = @filename+"~"
      begin
        file = File::open(@filename, "rb+")
        orig = true
      rescue Errno::ENOENT
        raise if read_only
        file = File::open(@filename, "wb+")
      end
      file.flock(read_only ? File::LOCK_SH : File::LOCK_EX)
      if read_only
        @table = TMarshal::load(file)
      elsif orig and (content = file.read) != ""
        @table = TMarshal::load(content)
        size = content.size
        md5 = Digest::MD5.digest(content)
        content = nil    # unreference huge data
      else
        @table = {}
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
          file.rewind
          content = TMarshal::dump(@table)
          if !md5 || size != content.size || md5 != Digest::MD5.digest(content)
            File::copy @filename, backup
            begin
              file.write(content)
              file.truncate(file.pos)
              content = nil    # unreference huge data
            rescue
              File::rename backup, @filename if File::exist?(backup)
              raise
            end
          end
        end
        if @abort and !orig
           File.unlink(@filename)
        end
        @abort = false
      end
    ensure
      @table = nil
      @transaction = false
      file.close if file
    end
    value
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

  db.transaction do
    db.roots.each do |k|
      p k, db[k]
    end
  end

  db.transaction do
    p db.root? ('Taro')
    p db.root? ('Hitoshi')
  end
end
