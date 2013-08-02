module Collective
  class Service
    autoload :DSL, 'collective/service/dsl'
    extend DSL

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def collect
      _instrument
    end
  end
end
