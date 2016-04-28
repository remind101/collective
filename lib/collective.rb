require 'rufus-scheduler'
require 'formatted-metrics'

require 'collective/version'

module Collective
  autoload :Collector, 'collective/collector'
  autoload :Builder,   'collective/builder'

  module Collectors
    autoload :Sidekiq,     'collective/collectors/sidekiq'
    autoload :Redis,       'collective/collectors/redis'
    autoload :Memcached,   'collective/collectors/memcached'
    autoload :RabbitMQ,    'collective/collectors/rabbitmq'
    autoload :Mongodb,     'collective/collectors/mongodb'
    autoload :Honeybadger, 'collective/collectors/honeybadger'
    autoload :Newrelic,    'collective/collectors/newrelic'
    autoload :PGBouncer,   'collective/collectors/pgbouncer'
    autoload :Postgres,    'collective/collectors/postgres'
    autoload :TrackJS,     'collective/collectors/trackjs'
  end

  class << self
    def run
      STDOUT.sync = true

      builder = Builder.new
      builder.instance_eval File.read('Collectfile'), __FILE__, __LINE__ - 1
      builder.run
    end
  end
end
