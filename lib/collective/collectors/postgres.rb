module Collective::Collectors
  # Options
  #   databases: a list of databases to monitor, e.g.
  #     [
  #       {
  #         name: "masterdb1",
  #         url: "masterurl",
  #         followers: [
  #           {
  #             name: "followerdb1",
  #             url: "followerurl"
  #           }
  #         ]
  #       }
  #     ]
  #
  class Postgres < Collective::Collector
    requires :pg

    resolution '60s'

    collect do
      databases.each do |db|
        group "postgres.lag_mb" do |group|
          db.stats.each do |follower_name, lag_mb|
            group.instrument follower_name, lag_mb
          end
        end
      end
    end

    private

    def databases
      Array(options[:databases]).map do |db|
        Database.new(db)
      end
    end

    class Database
      Follower = Struct.new(:name, :url)
      attr_reader :url, :name

      def initialize(db)
        @name      = db.fetch(:name)
        @url       = normalize_postgres_url(db.fetch(:url))
        @followers = Array(db[:followers]).map do |follower|
          Follower.new(follower.fetch(:name), normalize_postgres_url(follower.fetch(:url)))
        end
      end

      def stats
        m = get_master_stats
        @followers.each_with_object({}) do |follower, r|
          f = get_follower_stats(follower)

          xlog_offset_max = "FF000000".hex # offset goes up to this number within an xlog file
          lag_mb = (
            (xlog_offset_max * m[:xlog] + m[:offset]) -
            (xlog_offset_max * f[:xlog] + f[:offset])
          ) / 1024 / 1024

          # result can go negative since we're fetching data sequentially
          r[follower.name] = [lag_mb, 0].max
        end
      end

      private

      def normalize_postgres_url(url)
        uri = URI.parse(url)
        query = CGI.parse(String(uri.query))
        query.keep_if { |k, _| %w(options tty).include?(k) }
        uri.query = URI.encode_www_form(query)
        uri.to_s
      end

      def get_master_stats
        get_offset(@url, "pg_current_xlog_location()")
      end

      def get_follower_stats(follower)
        get_offset(follower.url, "pg_last_xlog_replay_location()")
      end

      def get_offset(url, function)
        connection = PG.connect(url)
        xlog, offset =
          connection.
          exec("SELECT #{function}").
          getvalue(0, 0).
          split(/\//).
          map(&:hex)

        { xlog: xlog, offset: offset }
      ensure
        connection.close if connection
      end
    end
  end
end

