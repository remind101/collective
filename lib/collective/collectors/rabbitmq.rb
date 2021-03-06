module Collective::Collectors
  class RabbitMQ < Collective::Collector
    requires :faraday
    requires :faraday_middleware
    requires :json

    collect do
      instrument_overview
      instrument_queues
      instrument_channels
    end

  private

    def instrument_channels
      nodes = client.get('nodes').body

      group 'rabbitmq' do |group|
        nodes.each do |node|
          instrument_hash(group, node, source: node['name'].to_s.gsub('@', '.'))
        end
      end
    end

    def instrument_overview
      overview = client.get('overview').body

      group 'rabbitmq' do |group|
        %w[message_stats object_totals queue_totals].each do |key|
          group.group key do |group|
            instrument_hash(group, overview[key])
          end
        end
      end
    end

    def instrument_queues
      queues = client.get('queues').body

      queues.each do |queue|
        group 'rabbitmq.queue' do |group|
          instrument_hash(group, queue, source: queue['name'])
        end
      end
    end

    def instrument_hash(group, hash, options={})
      return unless hash.respond_to?(:each)
      hash.each do |key, val|
        case val
        when Hash
          group.group key do |group|
            instrument_hash(group, val, options)
          end
        else
          group.instrument(key, val, options) if instrumentable?(val)
        end
      end
    end

    def client
      @client ||= Faraday.new(url) do |builder|
        builder.response :json, content_type: /\bjson$/
        builder.adapter Faraday.default_adapter
      end
    end

    def url
      options[:url]
    end

  end
end
