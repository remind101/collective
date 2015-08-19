require 'rufus-scheduler'
require 'formatted-metrics'

require 'collective/version'

module Collective
  autoload :Collector, 'collective/collector'
  autoload :Builder,   'collective/builder'

  module Collectors
    autoload :Honeybadger, 'collective/collectors/honeybadger'
    autoload :Memcached,   'collective/collectors/memcached'
    autoload :Mongodb,     'collective/collectors/mongodb'
    autoload :Newrelic,    'collective/collectors/newrelic'
    autoload :Postgres,    'collective/collectors/postgres'
    autoload :RabbitMQ,    'collective/collectors/rabbitmq'
    autoload :Redis,       'collective/collectors/redis'
    autoload :Sidekiq,     'collective/collectors/sidekiq'
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
