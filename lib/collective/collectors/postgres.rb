module Collective::Collectors
  class Postgres < Collective::Collector
    MEGABYTE = 1024 * 1024

    requires :pg

    collect do
      group 'postgres' do |group|
        instrument_relation_size_data group
      end
    end

    private

    def instrument_relation_size_data(group)
      size_tuples = conn.exec(size_query)
      size_tuples.each do |tuple|
        group.instrument tuple['relation'], (tuple['total_size'].to_f / MEGABYTE).round(2), units: 'MB'
      end
    end

    def size_query
      "SELECT relname AS 'relation', pg_total_relation_size(C.oid) AS 'total_size'
      FROM pg_class C
      LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
      WHERE nspname NOT IN ('pg_catalog', 'information_schema')
      AND C.relkind <> 'i'
      AND nspname !~ '^pg_toast';"
    end

    def conn
      @conn ||= PG.connect(connection_options)
    end

    def connection_options
      (options[:connection] || {}).merge(dbname: 'postgres')
    end
  end
end