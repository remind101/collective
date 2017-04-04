module Collective::Collectors
  class Fabric < Collective::Collector
    requires :fabricio

    resolution '24h'

    collect do
      group 'fabric' do |group|
        group.instrument 'ios.crash_free.sessions.7_days', crash_free_7_days
      end
    end

    def client
      Fabricio::Client.new do |config|
        config.username = fabric_username
        config.password = fabric_password
      end
    end

    def crash_free_7_days
      now = Date.today
      seven_days_ago = now - 7

      fabric.app.crashfree('53b2fb0fe499b52221000147', seven_days_ago.to_time.to_i, now.to_time.to_i, 'all')
    end

    def fabric_username
      options[:username]
    end

    def fabric_password
      options[:password]
    end
  end
end
