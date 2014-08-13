
module Hiki
  module Farm
    class Dispatcher
      def call(env)
        request = Hiki::Request.new(env)
        conf = ::Hiki::Farm::Config.load(File.join(Hiki::PATH, 'hikifarm_conf.rb'))
        case request.path_info
        when '/', "/#{Hiki::Farm::RSSPage.page_name}"
          Hiki::Farm::App.new(conf).call(env)
        when %r!\A/(\w+)/!
          hikiconf_rb = File.join(conf.farm_root, $1, 'hikiconf.rb')
          if File.exist?(hikiconf_rb)
            case $'
            when conf.attach_cgi_name
              Hiki::Attachment.new(hikiconf_rb).call(env)
            else
              Hiki::App.new(hikiconf_rb).call(env)
            end
          else
            not_found
          end
        else
          not_found
        end
      end

      private

      def not_found
        Hiki::Response.new("not found", 404, "Content-Type" => "text/plain")
      end

    end
  end
end
