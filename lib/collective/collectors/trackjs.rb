require 'pp'

module Collective::Collectors
  class TrackJS < Collective::Collector
    requires :faraday
    requires :faraday_middleware
    requires :json

    resolution '60s'

    # def initialize(mostRecentId = nil, options = {})
    #   @mostRecentId = mostRecentId
    #   @options = options
    # end

    collect do
      instrument_errors
    end

    private

    def instrument_errors
      paged("/#{customer_id}/v1/errors").each do |resp|
        p "resp"
        pp resp
        # p "most recent id"
        # pp mostRecentId
        errors = resp.body['data']

        errors.each do |error|
          instrument 'trackjs.url.errors', error['count'], source: error['key'], type: 'count'
        end
      end
    end

    # TODO: test paging
    def paged(path, params={})
      Enumerator.new do |yielder|
        page = 1
        pageSize = 500
        resp = get_page(path, params, page, pageSize)

        # TODO: test response handling
        while page < 2 do # resp.body['metadata']['hasMore'] == true do
          yielder.yield resp.body['data'] # pull out each error automatically?
          # @mostRecentId = page
          page += 1
          resp = get_page(path, params, page)
        end
      end
    end

    def get_page(path, params, page, pageSize)
      client.get(path, params.merge(page: page, size: pageSize)) do |req|
        req.headers['Authorization'] = api_key
      end
    end

    def client
      @client ||= Faraday.new(api_url) do |builder|
        builder.response :json, content_type: /\bjson$/
        builder.adapter Faraday.default_adapter
      end
    end

    def api_url
      "https://api.trackjs.com"
    end

    def customer_id
      options[:customer_id]
    end

    def api_key
      options[:api_key]
    end
  end
end
