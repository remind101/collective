module Collective::Collectors
  class Mongodb < Collective::Collector
    requires :mongoid

    collect do
      db = stats.delete('db')

      group 'mongodb' do |group|
        stats.each do |metric, value|
          group.instrument metric, value, source: db if instrumentable?(value)
        end
      end
    end

    private

    def stats
      session.command(dbStats: 1, scale: 1)
    end

    def session
      @session ||= begin
        Mongoid.load!(options[:config])
        Mongoid.default_session
      end
    end
  end
end
