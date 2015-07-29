module Collective::Collectors
  class Newrelic < Collective::Collector
    requires :faraday
    requires :faraday_middleware
    requires :json

    collect do
      group 'newrelic' do |group|
        instrument_applications group
        instrument_key_transactions group
      end
    end

    private

    def instrument_applications(group)
      paged('/v2/applications.json', 'applications').each do |app|
        next unless app['name'].include? filter

        group.group app['name'] do |group|
          instrument_appdex group, app
        end
      end
    end

    def instrument_key_transactions(group)
      # TODO: also apply application filter here?
      paged('/v2/key_transactions.json', 'key_transactions').each do |key_transaction|
        # Not sure if the names are quoted, replace
        sanitized_name = key_transaction['name'].gsub(/ /, '_')
        group.group sanitized_name do |group|
          instrument_appdex group, key_transaction
        end
      end
    end

    # Given an `info` hash that contains appdex summaries, instruments the
    # application and browser appdex scores
    def instrument_appdex(group, info)
      if info.include? 'application_summary'
        group.instrument 'response_time', info['response_time']
        group.instrument 'appdex_score', info['appdex_score']
      end
      if info.include? 'end_user_summary'
        group.group 'browser' do |group|
          group.instrument 'response_time', info['response_time']
          group.instrument 'appdex_score', info['appdex_score']
        end
      end
    end

    # Pages through items specified by `json_key` and yields them one at a time
    def paged(path, json_key)
      Enumerator.new do |yielder|
        page = 1
        resp = get path, page: page
        while resp.headers['Link'] || resp.body[json_key].length > 0 do
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
