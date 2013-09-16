#! /usr/bin/env ruby

$LOAD_PATH.unshift "."

require "optparse"
require "pathname"
require "fileutils"
require "digest/md5"
require "nkf"
require "hiki/util"
require "hiki/config"

FILE_NAME_MAX_SIZE = 255

def check(data_path, database_class, input_encoding, output_encoding, nkf)
  config = Struct.new(:data_path).new
  config.data_path = data_path.expand_path
  db = database_class.new(config)
  db.pages.each do |page|
    begin
      old_page = page
      escaped_old_page = Hiki::Util.escape(old_page)
      new_page = encode(old_page, input_encoding, output_encoding, nkf)
      escaped_new_page = Hiki::Util.escape(new_page)
      if escaped_new_page.bytesize > FILE_NAME_MAX_SIZE
        puts "NG: #{escaped_old_page} => #{escaped_new_page}"
      end
    rescue StandardError => ex
      puts "Error: #{escaped_old_page}"
      puts "#{ex.class}: #{ex.message}"
      puts ex.backtrace
    end
  end
end

def convert(data_path, database_class, input_encoding, output_encoding, nkf)
  config = Struct.new(:data_path).new
  config.data_path = data_path.expand_path
  db = database_class.new(config)
  db.pages.each do |page|
    begin
      old_page = page
      new_page = encode(old_page, input_encoding, output_encoding, nkf)
      print "#{Hiki::Util.escape(old_page)} => #{Hiki::Util.escape(new_page)}"
      old_text = db.load(old_page)
      new_text = encode(old_text, input_encoding, output_encoding, nkf)
      last_update = db.get_last_update(old_page)
      db.unlink(old_page)
      db.store(new_page, new_text, Digest::MD5.hexdigest(old_text))
      db.set_last_update(new_page, last_update)
      puts " OK."
    rescue StandardError => ex
      puts " NG."
      puts "#{ex.class}: #{ex.message}"
      puts ex.backtrace
    end
  end
  cache_path = data_path + "cache"
  FileUtils.rm_rf(cache_path)
end

def encode(text, input_encoding, output_encoding, nkf)
  if nkf
    NKF.nkf("-m0 --ic=#{input_encoding} --oc=#{output_encoding}", text)
  else
    text.dup.encode!(output_encoding, input_encoding, :invalid => :replace, :undef => :replace)
  end
end

def main(argv)
  parser = OptionParser.new
  data_path = nil
  repository_type = "plain"
  database_type = "flatfile"
  input_encoding = nil
  output_encoding = nil
  nkf = false
  check_only = false
  parser.on("-D", "--data-directory=DIR", "Specify the data directory"){|dir|
    data_path = Pathname(dir).realpath
  }
  # TODO Do we need to handle repository type?
  # parser.on("-r", "--repository-type=[TYPE]",
  #           "Specify the repository type [plain, svn, git, hg] (default: plain") {|type|
  #   repository_type = type
  # }
  parser.on("-d", "--database-type=[TYPE]",
            "Specify the database type [flatfile] (default: flatfile") {|type|
    database_type = type
  }
  parser.on("-i", "--input-encoding=ENCODING", "Specify the input encoding"){|encoding|
    input_encoding = Encoding.find(encoding)
  }
  parser.on("-o", "--output-encoding=ENCODING", "Specify the output encoding"){|encoding|
    output_encoding  = Encoding.find(encoding)
  }
  parser.on("--nkf", "Use NKF (default: no)"){
    nkf = true
  }
  parser.on("-C", "--check-only", "Check file name and exit"){
    check = true
  }

  begin
    parser.parse!(argv)
  rescue
    STDERR.puts $!.class.to_s
    STDERR.puts $!.message
    exit 1
  end

  # require_relative "../hiki/repos/#{repository_type}"
  # repository_class = ::Hiki.const_get("Repos#{repository_type.capitalize}")
  require_relative "../hiki/db/#{database_type}"
  database_class = ::Hiki::const_get("HikiDB_#{database_type}")

  if check_only
    check(data_path, database_class, input_encoding, output_encoding, nkf)
  else
    convert(data_path, database_class, input_encoding, output_encoding, nkf)
  end
end

if __FILE__ == $0
  main(ARGV)
end
