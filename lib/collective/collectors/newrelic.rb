module Collective::Collectors
  class Newrelic < Collective::Collector
    requires :faraday
    requires :faraday_middleware
    requires :json

    resolution '60s'

    collect do
      instrument_applications 'newrelic'
      instrument_key_transactions 'newrelic'
    end

    private

    def instrument_applications(prefix)
      paged('/v2/applications.json', 'applications').each do |app|
        next unless app['name'].include? filter
        next unless app['reporting']

        group "#{prefix}.#{app['name']}" do |group|
          instrument_apdex group, app
        end
      end
    end

    def instrument_key_transactions(prefix)
      # max_pages is a workaround for a new relic bug, it's currently returning the first page
      # if you ask for a non-existent page instead of returning an empty list (as it
      # does for /v2/applications.json)
      paged('/v2/key_transactions.json', 'key_transactions', max_pages=1).each do |key_transaction|
        # Not sure if the names are quoted, replace
        sanitized_name = key_transaction['name'].gsub(/ /, '_')
        group "#{prefix}.key.#{sanitized_name}" do |group|
          instrument_apdex group, key_transaction
        end
      end
    end

    # Given an `info` hash that contains appdex summaries, instruments the
    # application and browser appdex scores
    def instrument_apdex(group, info)
      if info.include? 'application_summary'
        group.instrument 'response_time', info['application_summary']['response_time'], units: 'ms'
        group.instrument 'apdex_score', info['application_summary']['apdex_score']
      end
      if info.include? 'end_user_summary'
        group.group 'browser' do |group|
          group.instrument 'response_time', info['end_user_summary']['response_time'], units: 's'
          group.instrument 'apdex_score', info['end_user_summary']['apdex_score']
        end
      end
    end

    # Pages through items specified by `json_key` and yields them one at a time
    def paged(path, json_key, max_pages=3)
      Enumerator.new do |yielder|
        page = 1
        resp = get path, page: page
        while resp.body[json_key].length > 0 && page <= max_pages do
          resp.body[json_key].each { |obj| yielder.yield obj }
          page += 1
          resp = get path, page: page
        end
      end
    end

    # Make an authenticated get request to the new relic api
    def get(path, options={})
      client.get(path, options) do |req|
        req.headers['X-Api-Key'] = api_key
      end
    end

    def client
      @client ||= Faraday.new(api_url) do |builder|
        builder.response :json, content_type: /\bjson$/
        builder.response :raise_error
        builder.adapter Faraday.default_adapter
      end
    end

    def api_key
      options[:api_key]
    end

    def api_url
      options[:api_url] || 'https://api.newrelic.com/'
    end

    # Specify to filter only applications whose name contains this string
    def filter
      options[:filter] || ''
    end
  end
end
