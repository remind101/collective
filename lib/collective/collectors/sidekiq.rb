module Collective::Collectors
  class Sidekiq < Collective::Collector
    requires :sidekiq

    collect do
      group 'sidekiq' do |group|
        group.instrument 'queues.processed', stats.processed, type: 'sample'
        group.instrument 'queues.failed',    stats.failed, type: 'sample'
        group.instrument 'queues.enqueued',  stats.enqueued, type: 'sample'
        group.instrument 'workers.busy',     workers, type: 'sample'

        queues.each do |queue, depth|
          group.instrument 'queue.latency', queue_latency(queue), source: queue, type: 'sample'
          group.instrument 'queue.enqueued', depth, source: queue, type: 'sample'
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
