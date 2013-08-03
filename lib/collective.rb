require 'rufus-scheduler'
require 'formatted-metrics'

require 'collective/version'

module Collective
  autoload :Collector, 'collective/collector'
  autoload :Builder,   'collective/builder'

  module Collectors
    autoload :Sidekiq, 'collective/collectors/sidekiq'
  end

  class << self
    def run
      Metrics.subscribe

      builder = Builder.new
      builder.instance_eval File.read('Collectfile')
      builder.run
    end
  end
end
