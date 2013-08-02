module Collective
  class Service
    module DSL
      def inherited(base)
        Collective.register(base)
      end

      def requires(libs)
        Array(libs).each { |lib| require lib.to_s }
      end

      def collect(&block)
        define_method :collect, &block
      end
    end
  end
end
