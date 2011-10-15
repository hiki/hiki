
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
          Hiki::App.new(File.join(conf.farm_root, $1, 'hikiconf.rb')).call(env)
        end
      end
    end
  end
end
