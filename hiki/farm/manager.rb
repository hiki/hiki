# -*- coding: utf-8 -*-
require 'hiki/util'
require "fileutils"

module Hiki
  module Farm
    class Manager
      include FileUtils

      attr_reader :wikilist

      def initialize(conf)
        @conf = conf
        farm_pub_path = @conf.farm_root
        ruby          = @conf.ruby
        repos_type    = @conf.repos_type
        repos_root    = @conf.repos_root
        data_root     = @conf.data_root
        require "hiki/repos/#{repos_type}"
        @repos = Hiki.const_get("HikifarmRepos#{repos_type.capitalize}").new(repos_root, data_root)
        @ruby = ruby
        @wikilist = []
        @farm_pub_path = farm_pub_path

        Dir["#{@farm_pub_path}/*"].each do |wiki|
          wiki.untaint
          next if not FileTest.directory?(wiki)
          next if FileTest.symlink?(wiki)
          next if not FileTest.file?("#{wiki}/hikiconf.rb")

          begin
            @wikilist << Wiki.new(File.basename(wiki), data_root)
          rescue
          end
        end
      end

      def wikis_num
        @wikilist.size
      end

      def pages_num
        @wikilist.inject(0){|result, wiki| result + wiki.pages_num }
      end

      def create_wiki(name)
        mkdir_p("#{@farm_pub_path}/#{name.untaint}")

        unless Object.const_defined?(:Rack)
          create_index_cgi(name)
          create_attach_cgi(name)
        end

        # create hikiconf.rb
        File.open("#{@farm_pub_path}/#{name}/hikiconf.rb", 'w') do |f|
          f.puts(conf(name, @conf.hiki))
        end

        mkdir_p("#{@conf.data_root}/#{name}")
        mkdir_p("#{@conf.data_root}/#{name}/text")
        mkdir_p("#{@conf.data_root}/#{name}/backup")
        mkdir_p("#{@conf.data_root}/#{name}/cache")
        require 'fileutils'
        Dir["#{@conf.default_pages_path}/*"].each do |f|
          f.untaint
          cp(f, "#{@conf.data_root}/#{name}/text/#{File.basename(f)}") if File.file?(f)
        end

        @repos.import(name)
      end

      def command_key
        "c"
      end

      def command_query(name)
        "?#{command_key}=#{Hiki::Util.escape(name)}"
      end

      private

      def create_index_cgi(name)
        index_cgi_path = File.join(@farm_pub_path, name, @conf.cgi_name)
        File.open(index_cgi_path, 'w') do |f|
          f.puts(index(name, @conf.hiki))
          f.chmod(0744)
        end
      end

      def create_attach_cgi(name)
        return unless attach_cgi_name
        attach_cgi_path = File.join(@farm_pub_path, name, @conf.attach_cgi_name)
        File.open(attach_cgi_path, 'w') do |f|
          f.puts(attach(name, @conf.hiki))
          f.chmod(0744)
        end
      end

      def conf(wiki, hiki)
        __my_wiki_name__ = wiki
        # FIXME: maybe wrong path to template file
        return ERB.new(File.read("#{hiki}/hiki.conf.erb")).result(binding)
      end

      # not in use
      def index(wiki, hiki)
        <<-INDEX
#!#{@ruby}
hiki=''
eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
$:.unshift "\#{hiki}"
load "\#{hiki}/hiki.cgi"
INDEX
      end

      # not in use
      def attach(wiki, hiki)
        <<-INDEX
#!#{@ruby}
hiki=''
eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
$:.unshift "\#{hiki}"
load "\#{hiki}/misc/plugin/attach/attach.cgi"
INDEX
      end
    end
  end
end
