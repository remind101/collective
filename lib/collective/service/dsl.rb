module Collective
  class Service
    module DSL
      def inherited(base)
        Collective.register(base)
      end

      def requires(libs)
        Array(libs).each { |lib| require lib.to_s }
      end

      def instrument(&block)
        define_method :_instrument, &block
      end
    end
  end
end
