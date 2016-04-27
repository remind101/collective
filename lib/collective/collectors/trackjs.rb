require 'pp'

module Collective::Collectors
  class TrackJS < Collective::Collector
    requires :faraday
    requires :faraday_middleware
    requires :json

    resolution '60s'

    def initialize(lastSeenId = nil, options)
      @lastSeenId = lastSeenId
      super(options)
    end

    collect do
      p "COLLECT@@@@@@@@@@@@@@@@@@@@@@@"
      instrument_errors
    end

    private

    def instrument_errors
      count = 0
      application = ""
      paged("/#{customer_id}/v1/errors").each do |error|
        p "tracking an error"
        p "rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr"
        application = error['application'] if count == 0
        count += 1
      end
      p "LOGGING #{count} errors to the collector for application #{application}"
      instrument 'trackjs.url.errors', count, source: application, type: 'count'
    end

    # This function goes through a paged list of errors and yields each
    # individual error.
    #
    # The most basic endpoint in the TrackJS API returns all the errors that
    # have been detected from the beginning of time to the current date. This
    # endpoint can return the number of errors seen in the last day, but since
    # we're just trying to determine the number of errors that occurred in the
    # last 60s, we use the default endpoint options.
    #
    # To avoid fetching all the errors, only the ones we haven't seen since
    # the last time we checked, so we keep track of the id of the last error
    # we saw and page through the error list until either:
    #
    # 1. We see an error we've already returned
    # 2. We hit a maximum page limit (to avoid scanning the entire list of
    #    errors the first time the collector is run)
    # 3. We hit the very end of the error list
    #
    def paged(path, params={})
      Enumerator.new do |yielder|
        page = 1
        pageSize = 250
        maxPages = 1
        resp = get_page(path, params, page, pageSize)
        currentInitialId = nil
        getAnotherPage = true # set to true until an error id that has already been seen is hit

        p "response metadata"
        p resp.body['metadata']
        p "@lastSeenId"
        p @lastSeenId
        p "************************************************"

        data = resp.body['data']
        if data.length
          currentInitialId = data[0]['id']
          p "storing most recent Id:"
          p currentInitialId
          p "************************************************"

          while resp.body['metadata']['hasMore'] == true and page <= maxPages do
            resp.body['data'].each do |error|
              p "error"
              p error['message']
              p error['id']
              if error['id'] == @lastSeenId
                p "BREAKING OUT OF LOOP. I'VE SEEN THIS ERROR BEFORE"
                getAnotherPage = false
                break
              else
                yielder.yield error
              end
            end

            if getAnotherPage
              p ">>>going to get another page"
              page += 1
              resp = get_page(path, params, page, pageSize)
            else
              break
            end
          end
          # check why i broke out of the while loop
          # options:
          # hit something i'd seen before
          # hit the very end of the errors list
          # hit the max page limit
          if getAnotherPage == false
            p "1111111 Finished while loop because I saw an error i'd seen before"
          elsif page > maxPages
            p "2222222 Finished while loop because I hit the max page limit"
          else
            p "3333333 Finished while loop because I hit the end of the errors list"
          end
          p "setting last seen id to"
          p currentInitialId
          @lastSeenId = currentInitialId
        end
      end
    end

    def get_page(path, params, page, pageSize = 500)
      p "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!>>>>>>>>>>>>"
      p "getting a new page of results"
      p "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!>>>>>>>>>>>>"
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
