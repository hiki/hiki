#! /usr/bin/env ruby

$LOAD_PATH.unshift '.'

require "optparse"
require "pathname"
require "fileutils"
require "digest/md5"
require "hiki/util"
require "hiki/config"

def convert(data_path, database_class, input_encoding, output_encoding)
  config = Struct.new(:data_path).new
  config.data_path = data_path.expand_path
  db = database_class.new(config)
  options = { invalid: :replace, undef: :replace }
  db.pages.each do |page|
    old_page = page
    new_page = old_page.dup.encode!(output_encoding, input_encoding, options)
    old_text = db.load(old_page)
    new_text = old_text.dup.encode!(output_encoding, input_encoding, options)
    if old_page == new_page
      db.unlink(old_page)
    else
      db.rename(old_page, new_page)
    end
    db.store(new_page, new_text, Digest::MD5.hexdigest(old_text))
  end
  cache_path = data_path + "cache"
  FileUtils.rm_rf(cache_path)
end

def main(argv)
  parser = OptionParser.new
  data_path = nil
  repository_type = "plain"
  database_type = "flatfile"
  input_encoding = nil
  output_encoding = nil
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

  convert(data_path, database_class, input_encoding, output_encoding)
end

if __FILE__ == $0
  main(ARGV)
end
