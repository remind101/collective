module Collective::Collectors
  class Redis < Collective::Collector
    MEGABYTE = 1024 * 1024

    requires :redis

    collect do
      instrument 'redis.used_memory',       (info['used_memory'].to_f / MEGABYTE).round(2)
      instrument 'redis.connected_clients', info['connected_clients']
      instrument 'redis.blocked_clients',   info['blocked_clients']
      instrument 'redis.connected_slaves',  info['connected_slaves']
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
