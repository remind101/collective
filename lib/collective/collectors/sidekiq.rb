module Collective::Collectors
  class Sidekiq < Collective::Collector
    requires :sidekiq

    collect do
      instrument 'sidekiq.queues.processed', stats.processed
      instrument 'sidekiq.queues.failed',    stats.failed
      instrument 'sidekiq.queues.enqueued',  stats.enqueued
      instrument 'sidekiq.workers.busy',     workers

      queues.each do |queue, depth|
        instrument 'sidekiq.queue.enqueued', depth, source: queue
      end
    end

  private

    def stats
      ::Sidekiq::Stats.new
    end

    def queues
      stats.queues
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
