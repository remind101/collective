module Collective::Collectors
  class PGBouncer < Collective::Collector
    requires :pg

    collect do
      group 'pgbouncer' do |group|
        instrument group, 'stats'
        instrument group, 'pools'
      end
    end

  private

    def instrument(group, thing)
      group.group thing do |group|
        instrument_tuples group, show(thing)
      end
    end

    def show(thing)
      conn.exec "show #{thing};"
    end

    def instrument_tuples(group, tuples)
      tuples.each do |tuple|
        source = tuple.key?('database') ? tuple['database'] : ''
        tuple.each do |k,v|
          group.instrument(k, v, source: source) if instrumentable?(v)
        end
      end
    end

    def conn
      @conn ||= PG.connect(connection_options)
    end

    def connection_options
      (options[:connection] || {}).merge(dbname: 'pgbouncer')
    end
  end
end
