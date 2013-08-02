require 'rufus-scheduler'
require 'formatted-metrics'

require 'collective/version'

module Collective
  autoload :Service, 'collective/service'

  module Services
    autoload :Sidekiq, 'collective/services/sidekiq'
  end

  class << self
    def services
      @services ||= []
    end

    def register(service)
      services << service
    end

    def run
      Metrics.subscribe

      services.map(&:new).each do |service|
        scheduler.every '1s' do
          service.collect
        end
      end

      scheduler.join
    end

    def scheduler
      @scheduler ||= Rufus::Scheduler.new
    end
  end
end
