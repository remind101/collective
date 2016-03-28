module Collective::Collectors
  class Postgres < Collective::Collector
    MEGABYTE = 1024 * 1024

    requires :pg

    resolution '600s'

    collect do
      group "postgres.#{connection_options[:dbname]}" do |group|
        instrument_relation_size_data group
      end
    end

    private

    def instrument_relation_size_data(group)
      begin
        conn = PG.connect(connection_options)
        size_tuples = conn.exec(size_query)
        size_tuples.each do |tuple|
          group.instrument "#{tuple['relation']}.size", (tuple['total_size'].to_f / MEGABYTE).round(2), units: 'MiB'
          group.instrument 'total_disk_usage', (tuple['total_size'].to_f / MEGABYTE).round(2), units: 'MiB', tags: {relation: tuple['relation']}
        end
      ensure
        conn.close if conn != nil
      end
    end

    def size_query
      "SELECT relname AS relation, pg_total_relation_size(C.oid) AS total_size
      FROM pg_class C
      LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
      WHERE nspname NOT IN ('pg_catalog', 'information_schema')
      AND C.relkind <> 'i'
      AND nspname !~ '^pg_toast';"
    end

    def connection_options
      options[:connection] || {}
    end
  end
end