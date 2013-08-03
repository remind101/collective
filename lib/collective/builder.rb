module Collective
  class Builder
    DEFAULT_RESOLUTION = '5s'.freeze

    def use(klass, *args)
      collectors << [klass, args]
    end

    def run
      collectors.each do |(klass, args)|
        collector = klass.new(*args)
        scheduler.every klass.resolution || DEFAULT_RESOLUTION do
          collector.collect
        end
      end

      scheduler.join
    end

  private

    def collectors
      @collectors ||= []
    end

    def scheduler
      @scheduler ||= Rufus::Scheduler.new
    end
  end
end
