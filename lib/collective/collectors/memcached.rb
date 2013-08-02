module Collective::Collectors
  class Memcached < Collective::Collector
    requires :dalli

    collect do
      client.stats.each do |server, stats|
        stats.each do |metric, value|
          instrument "memcached.#{metric}", value, source: server
        end
      end
    end

    def client
      ::Dalli::Client.new(url)
    end

    def url
      options[:url] || ENV['MEMCACHED_URL']
    end
  end
end
