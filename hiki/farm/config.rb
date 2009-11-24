# -*- coding: utf-8 -*-

module Hiki
  module Farm
    class Config
      attr_reader(:ruby, :hiki, :hikifarm_description, :farm_root,
                  :default_pages_path, :data_root, :repos_type, :repos_root,
                  :title, :css, :author, :mail, :cgi_name, :attach_cgi_name,
                  :header, :footer, :cgi, :hikifarm_template_dir, :charset)
      attr_writer :repos_type

      def self.load(path)
        c = new()
        c.instance_eval(File.read(path))
        # set default values
        c.repos_type ||= 'default'
        c
      end
    end
  end
end
