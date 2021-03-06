module Collective::Collectors
  class Redis < Collective::Collector
    MEGABYTE = 1024 * 1024

    requires :redis

    collect do
      group 'redis' do |group|
        group.instrument 'used_memory',       (info['used_memory'].to_f / MEGABYTE).round(2)
        group.instrument 'connected_clients', info['connected_clients']
        group.instrument 'blocked_clients',   info['blocked_clients']
        group.instrument 'connected_slaves',  info['connected_slaves']
      end
    end

  private

    def info
      redis.info
    end

    def redis
      @redis ||= url ? ::Redis.new(url: url) : ::Redis.new
    end

    def url
      options[:url]
    end
  end
end
