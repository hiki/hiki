require "hiki/repository/base"
require "sequel"

module Hiki
  module Repository
    class RDB < Base
      attr_writer :db

      Repository.register(:rdb, self)

      def initialize(database_url, data_path)
        @database_url = database_url
        @data_path = data_path
      end

      def commit(page, msg = default_msg)
      end

      def delete(page, msg = default_msg)
      end

      def get_revision(page, revision)
        connect = Sequel.connect(ENV["DATABASE_URL"] || @database_url)
        record = connect[:page_backup].where(wiki: @db.wiki, name: page, revision: revision).limit(1).select(:body).first
        connect.disconnect

        if record && record[:body]
          record[:body]
        else
          ""
        end
      end

      def revisions(page)
        connect = Sequel.connect(ENV["DATABASE_URL"] || @database_url)
        records = connect[:page_backup].where(wiki: @db.wiki, name: page).order(:revision).select(:revision, :last_modified, :editor)
        connect.disconnect

        records.map do |record|
          [
            record[:revision],
            "%04d/%02d/%02d %02d:%02d:%02d" % [record[:last_modified].year, record[:last_modified].month, record[:last_modified].day, record[:last_modified].hour, record[:last_modified].min, record[:last_modified].sec],
            nil,
            record[:editor] || "Anonymous"
          ]
        end
      end
    end
  end
end
