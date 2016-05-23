module Collective::Collectors
  class TrackJS < Collective::Collector
    requires :faraday
    requires :faraday_middleware
    requires :json
    @@frequency = 60 # seconds

    resolution @@frequency.to_s + 's'

    def initialize(options = {})
      @last_seen_id = options[:last_seen_id] || {}
      super(options)
    end

    collect do
      options[:applications].each do |application|
        instrument_errors application
      end
    end

    private

    def instrument_errors(application)
      count = 0
      paged("/#{customer_id}/v1/errors", {application: application}).each do |error|
        count += 1
      end
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
    # 2. We hit an errors that's more than 60s old (to avoid scanning the entire list of
    #    errors the first time the collector is run)
    # 3. We hit the very end of the error list
    #
    def paged(path, params={})
      Enumerator.new do |yielder|
        current_error_time = Time.now.utc
        oldest_error = current_error_time - @@frequency
        page = 1
        page_size = 250
        current_initial_id = nil
        get_another_page = true # set to true until an error id that has already been seen is hit
        application = params[:application]

        resp = get_page(path, params, page, page_size)
        data = resp.body['data']

        if data.length > 0
          current_initial_id = data[0]['id']

          while current_error_time > oldest_error do
            resp.body['data'].each do |error|
              current_error_time = Time.parse(error['timestamp'])
              if (error['id'] == @last_seen_id[application]) || (current_error_time <= oldest_error)
                get_another_page = false
                break
              else
                yielder.yield error
              end
            end

            break if !get_another_page or !resp.body['metadata']['hasMore']

            page += 1
            resp = get_page(path, params, page, page_size)
          end

          @last_seen_id[application] = current_initial_id
        end
      end
    end

    def get_page(path, params, page, page_size = 500)
      client.get(path, params.merge(page: page, size: page_size)) do |req|
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
