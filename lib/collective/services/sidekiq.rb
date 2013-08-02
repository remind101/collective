module Collective::Services
  class Sidekiq < Collective::Service
    requires :sidekiq

    instrument do
      instrument 'queues.processed', stats.processed
      instrument 'queues.failed',    stats.failed
      instrument 'queues.enqueued',  stats.enqueued
      instrument 'workers.busy',     workers

      stats.queues.each do |queue, depth|
        instrument 'queue.enqueued', depth, queue
      end

      # General redis metrics
      info = Sidekiq.redis { |conn| conn.info }
      instrument 'redis.used_memory', ( info['used_memory'].to_f / MEGABYTE ).round(2)
      instrument 'redis.connected_clients', info['connected_clients']
      instrument 'redis.blocked_clients', info['blocked_clients']
      instrument 'redis.connected_slaves', info['connected_slaves']
      instrument 'redis.ops_per_sec', info['instantaneous_ops_per_sec']
    end

    def stats
      ::Sidekiq::Stats.new
    end

    def workers
      ::Sidekiq.redis { |conn|
        conn
        .smembers('workers')
        .map { |w| conn.get("worker:#{w}") }
        .compact
      }.length
    end
  end
end
