module Collective
  class Collector
    autoload :DSL, 'collective/collector/dsl'
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

    def group(*args, &block)
      Metrics.group(*args, &block)
    end

  private

    def instrumentable?(value)
      Float(value) rescue nil
    end
  end
end
