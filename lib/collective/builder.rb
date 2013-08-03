module Collective
  class Builder
    def use(klass, *args)
      collectors << [klass, args]
    end

    def run
      collectors.each do |(klass, args)|
        collector = klass.new(*args)
        scheduler.every '1s' do
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
