# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require "fileutils"
require "ptstore"
require "hiki/util"
require "hiki/storage/base"

module Hiki
  module Storage
    class Flatfile < Base
      Storage.register(:flatfile, self)

      attr_reader :pages_path

      def initialize(conf)
        @conf = conf
        @pages_path = File.join(@conf.data_path, "text")
        @backup_path = File.join(@conf.data_path, "backup")
        @info_db = File.join(@conf.data_path, "info.db")
        create_missing_dirs
        create_infodb unless test(?e, @info_db)
        @info = PTStore.new(@info_db)
      end

      def close_db
        true
      end

      def store(page, text, md5, update_timestamp = true)
        backup(page)
        filename = textdir(page)

        if exist?(page)
          return nil if md5 != md5hex(page)
          if update_timestamp
            FileUtils.copy(filename, backupdir(page), { preserve: true })
          end
        end
        create_info_default(page) unless info_exist?(page)

        if update_timestamp
          set_last_update(page, Time.now)
        end
        File.open(filename, "wb") do |f|
          f.write(text.gsub(/\r\n/, "\n"))
        end
        true
      end

      def unlink(page)
        if exist?(page)
          begin
            FileUtils.copy(textdir(page), backupdir(page), { preserve: true })
            delete_info(page)
            File.unlink(textdir(page))
          rescue
          end
        end
      end

      def load(page)
        return nil unless exist?(page)
        File.read(textdir(page))
      end

      def load_backup(page)
        return nil unless backup_exist?(page)
        File.read(backupdir(page))
      end

      def exist?(page)
        test(?e, textdir(page))
      end

      def backup_exist?(page)
        test(?e, backupdir(page))
      end

      def pages
        Dir.glob("#{@pages_path}/*").delete_if {|f| !test(?f, f.untaint)}.collect! {|f|
          unescape(File.basename(f))
        }
      end

      def rename(old_page, new_page)
        raise ArgumentError, "#{new_page} has already existed." if exist?(new_page)
        text = load(old_page)
        store(new_page, text, md5hex(text))
        unlink(old_page)
      end

      # ==============
      #   info DB
      # ==============
      def info_exist?(page)
        f = escape(page)
        @info.transaction(true) do
          @info.root?(f)
        end
      end

      def infodb_exist?
        test(?e, @info_db)
      end

      def info(page)
        f = escape(page)
        @info.transaction(true) do
          @info.root?(f) ? @info[f] : nil
        end
      end

      def page_info
        h = []
        @info.transaction(true) do
          @info.roots.each { |a| h << { unescape(a) => @info[a]} }
        end
        h
      end

      def set_attribute(page, attr)
        f = escape(page)
        @info.transaction do
          @info[f] = default unless @info[f]
          attr.each do |attribute, value|
            @info[f][attribute] = value
          end
        end
      end

      def get_attribute(page, attribute)
        f = escape(page)
        @info.transaction(true) do
          if @info.root?(f)
            @info[f][attribute] || default[attribute]
          else
            default[attribute]
          end
        end
      end

      def select
        result = []
        @info.transaction(true) do
          @info.roots.each do |a|
            result << unescape(a) if yield(@info[a])
          end
        end
        result
      end

      def increment_hitcount(page)
        f = escape(page)
        @info.transaction do
          @info[f][:count] = @info[f][:count] + 1
        end
      end

      def get_hitcount(page)
        get_attribute(page, :count)
      end

      def freeze_page(page, freeze)
        set_attribute(page, [[:freeze, freeze]])
      end

      def is_frozen?(page)
        get_attribute(page, :freeze)
      end

      def set_last_update(page, t)
        set_attribute(page, [[:last_modified, t]])
      end

      def get_last_update(page)
        get_attribute(page, :last_modified)
      end

      def set_references(page, r)
        set_attribute(page, [[:references, r]])
      end

      def get_references(page)
        ref = []
        page_info.each do |a|
          r = a.values[0][:references]
          if String === r # for compatibility
            r = r.split(",")
            set_references(a.keys[0], r)
          end
          ref << a.keys[0] if r.include?(page)
        end
        ref
      end

      private

      def create_missing_dirs
        [@pages_path, @backup_path].each {|d|
          FileUtils.mkdir_p(d) unless FileTest.exist?(d)
        }
      end

      def delete_info(page)
        f = escape(page)
        begin
          @info.transaction do
            @info.delete(f)
          end
        rescue
        end
      end

      def create_infodb
        @info = PTStore.new(@info_db)
        @info.transaction do
          pages.each do |a|
            r = default
            r[:last_modified] = File.mtime("#{@pages_path}/#{escape(a)}".untaint)
            @info[escape(a)]  = r
          end
        end
      end

      def create_info_default(page)
        f = escape(page)
        @info.transaction do
          @info[f] = default
        end
      end

      def default
        { count: 0,
          last_modified: Time.now,
          freeze: false,
          references: [],
          keyword: [],
          title: "",
        }
      end

      def textdir(s)
        File.join(@pages_path, escape(s)).untaint
      end

      def backupdir(s)
        File.join(@backup_path, escape(s)).untaint
      end
    end
  end
end
