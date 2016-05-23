require 'securerandom'
require 'faker'

module TrackJSHelpers
  def trackjs_error(
    message: nil,
    timestamp: Time.now.utc.strftime("%FT%T%:z"),
    url: "https://www.remind.com",
    application: "r101-frontend",
    id: SecureRandom.uuid
  )
    trackjs_url = "https://my.trackjs.com/details/#{id}"
    message = message || Faker::Lorem.sentence

    return {
      "message" => message,
      "timestamp" => timestamp,
      "url" => url,
      "id" => id,
      "browserName" => "Chrome",
      "browserVersion" => "49.0.2623",
      "entry" => "window",
      "application" => application,
      "line" => 11,
      "column" => 13161,
      "file" => "https://www.remind.com/classes/sci02",
      "userId" => "11111111",
      "sessionId" => "",
      "trackJsUrl" => trackjs_url,
      "isStarred" => false
    }
  end

  def trackjs_metadata(total_count: 0, page: 1, page_size: 250, has_more: true)
    return {
      "totalCount" => total_count,
      "page" => page,
      "size" => page_size,
      "hasMore" => has_more,
      "trackJsUrl" => "https://my.trackjs.com/recent?"
    }
  end

  def trackjs_response(errors: 0, timestamps: nil, total_errors: 0, page: 1, page_size: 250)
    timestamps = timestamps || errors.times.map { Time.now.utc.strftime("%FT%T%:z") }
    data = errors.times.map do |i|
      trackjs_error(timestamp: timestamps[i])
    end
    has_more = (page * page_size) < total_errors

    return {
      "data" => data,
      "metadata" => trackjs_metadata(
        total_count: total_errors,
        page: page,
        page_size: page_size,
        has_more: has_more
      )
    }
  end
end

RSpec.configure do |config|
  config.include TrackJSHelpers
end
