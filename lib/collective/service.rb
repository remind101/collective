module Collective
  class Service
    autoload :DSL, 'collective/service/dsl'
    extend DSL

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def collect!
      collect
    end

    def instrument(*args, &block)
      Metrics.instrument(*args, &block)
    end
  end
end
