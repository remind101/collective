module Collective::Collectors
  class Sidekiq < Collective::Collector
    requires :sidekiq

    collect do
      group 'sidekiq' do |group|
        group.instrument 'queues.processed', stats.processed
        group.instrument 'queues.failed',    stats.failed
        group.instrument 'queues.enqueued',  stats.enqueued
        group.instrument 'workers.busy',     workers

        queues.each do |queue, depth|
          group.instrument 'queue.latency', queue_latency(queue), source: queue
          group.instrument 'queue.enqueued', depth, source: queue
        end
      end
    end

  private

    def stats
      ::Sidekiq::Stats.new
    end

    def queues
      stats.queues
    end

    def queue_latency(name)
      ::Sidekiq::Queue.new(name).latency rescue 0
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
