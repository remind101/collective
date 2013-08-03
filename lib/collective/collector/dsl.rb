module Collective
  class Collector
    module DSL
      def requires(libs)
        Array(libs).each { |lib| require lib.to_s }
      end

      def collect(&block)
        define_method :collect, &block
      end

      def resolution(resolution = nil)
        @resolution = resolution if resolution
        @resolution
      end
    end
  end
end
