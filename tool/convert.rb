#! /usr/bin/env ruby

$:.unshift '.'

require "optparse"
require "pathname"
require "hiki/util"

def convert(data_dir, repository_class, input_encoding, output_encoding)
  repository = repository_class.new(nil, data_dir)
  repository.pages do |page|
    new_page = page.encode!(output_encoding, input_encoding)
    repository.rename(page, new_page)
  end
  repository.pages do |page|
    latest_revision = repository.revisions(page).first.last
    content = repository.get_revision(page, latest_revision)
    repository.commit_with_content(page, content.encode!(output_encoding, input_encoding))
  end
end

def main(argv)
  parser = OptionParser.new
  data_dir = nil
  repository_type = "plain"
  input_encoding = nil
  output_encoding = nil
  parser.on("-d", "--data-directory=DIR", "Specify the data directory"){|dir|
    data_dir = dir
  }
  parser.on("-r", "--repository-type=[TYPE]",
            "Specify the repository type [plain, svn, git, hg] (default: plain") {|type|
    repository_type = type
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

  require_relative "../hiki/repos/#{repository_type}"
  repository_class = ::Hiki.const_get("Repos#{repository_type}")

  convert(data_dir, repository_class, input_encoding, output_encoding)
end

if __FILE__ == $0
  main(ARGV)
end
