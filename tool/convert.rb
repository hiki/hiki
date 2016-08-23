#!/usr/local/opt/ruby/bin/ruby
#! /usr/bin/env ruby

# $LOAD_PATH.unshift "."
$LOAD_PATH.unshift "../lib"

require "optparse"
require "pathname"
require "fileutils"
require "digest/md5"
require "nkf"
require "hiki/util"
require "hiki/config"
require "ptstore"

FILE_NAME_MAX_SIZE = 255

def convert_info_db(data_path, input_encoding, output_encoding, nkf)

  info_db_path = data_path + "info.db"
  db = PTStore.new(info_db_path)

  db.transaction do
    db.roots.each do |d|
      db[d][:title] = encode(db[d][:title], input_encoding, output_encoding, nkf)
      db[d][:references].map! do |r|
        encode(r, input_encoding, output_encoding, nkf)
      end
    end
    db.roots.each do |d|
      d_new = Hiki::Util.escape(encode(Hiki::Util.unescape(d),
                                       input_encoding, output_encoding, nkf))
      db[d_new] = db[d]
      db.delete d if d_new != d
    end
    db.commit
  end
end

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
      old_page = page.force_encoding(input_encoding)
      new_page = encode(old_page, input_encoding, output_encoding, nkf)
      print "#{new_page}: #{Hiki::Util.escape(old_page)} => #{Hiki::Util.escape(new_page)}"
      convert_attachments(data_path, old_page, new_page, input_encoding,
                          output_encoding, nkf)
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
  cache_path = data_path + "cache/parser/"
  FileUtils.rm_rf(cache_path)
end

def convert_attachments(data_path, old_page, new_page, input_encoding,
                        output_encoding, nkf)
  attach_path = data_path + "cache/attach/"
  escaped_old_page = Hiki::Util.escape(old_page)
  escaped_new_page = Hiki::Util.escape(new_page)
  old_attachments_dir = attach_path + escaped_old_page
  new_attachments_dir = attach_path + escaped_new_page
  if old_attachments_dir.exist?
    Dir.glob("#{old_attachments_dir}/*").each do |old_file_fullpath|
      old_file = File.basename(old_file_fullpath)
      new_file = Hiki::Util.escape(encode(Hiki::Util.unescape(old_file),
                                          input_encoding, output_encoding, nkf))
      new_file_fullpath = "#{old_attachments_dir}/#{new_file}"
      if old_file != new_file
        FileUtils.mv(old_file_fullpath, new_file_fullpath)
      end
    end
    if escaped_old_page != escaped_new_page
      FileUtils.mv(old_attachments_dir, new_attachments_dir)
    end
  end
end

def encode(text, input_encoding, output_encoding, nkf)
  NKF.nkf(  "-Ew" , text)
#  if nkf
#    NKF.nkf("-m0 --ic=#{input_encoding} --oc=#{output_encoding}", text)
#  else
#    text.dup.encode!(output_encoding, input_encoding, invalid: :replace, undef: :replace)
#  end
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
#  require_relative "../hiki/db/#{database_type}"
  require_relative "../lib/hiki/storage/#{database_type}"
#  database_class = ::Hiki::const_get("HikiDB_#{database_type}")
  database_class = ::Hiki::Storage::Flatfile
  if check_only
    check(data_path, database_class, input_encoding, output_encoding, nkf)
  else
    convert_info_db(data_path, input_encoding, output_encoding, nkf)
    convert(data_path, database_class, input_encoding, output_encoding, nkf)
  end
end

if __FILE__ == $0
  main(ARGV)
end
