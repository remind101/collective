module Collective::Collectors
  class Honeybadger < Collective::Collector
    requires :faraday
    requires :faraday_middleware
    requires :json

    resolution '60s'

    collect do
      instrument_exceptions
    end

  private

    def instrument_exceptions
      each_result('/v1/projects') do |project|
        id = project['id']
        totals_by_env = Hash.new { |hash, key| hash[key] = 0 }

        each_result("/v1/projects/#{id}/faults", resolved: 'f') do |fault|
          totals_by_env[fault['environment']] += fault['notices_count']
        end

        totals_by_env.each do |env, total|
          instrument 'honeybadger.faults.notices', total, source: "%s.%s" % [project['name'], env], type: 'count'
        end
      end
    end

    def each_result(path, params={})
      page = 1
      resp = get_page(path, params, page)

      while resp.body['num_pages'] > page do
        resp.body['results'].each do |obj|
          yield obj
        end
        page += 1
        resp = get_page(path, params, page)
      end
    end

    def get_page(path, params, page)
      client.get(path, params.merge(auth_token: auth_token, page: page))
    end

    def client
      @client ||= Faraday.new(url) do |builder|
        builder.response :json, content_type: /\bjson$/
        builder.adapter Faraday.default_adapter
      end
    end

    def url
      "https://api.honeybadger.io"
    end

    def auth_token
      options[:auth_token]
    end
  end
end
