require 'thor'

module Collective
  class CLI < Thor
    include Thor::Actions

    desc 'start', 'Run the collector'

    def start
      load 'Collectfile'
      Collective.run
    end
  end
end
