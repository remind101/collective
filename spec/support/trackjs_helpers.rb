require 'securerandom'
require 'faker'

module TrackJSHelpers
  def trackjs_error(params = {
    message: nil,
    timestamp: Time.now.strftime("%FT%T%:z"),
    url: "https://www.remind.com",
    application: "r101-frontend",
    id: SecureRandom.uuid
  })
    trackjs_url = "https://my.trackjs.com/details/#{params[:id]}"
    params[:message] ||= Faker::Lorem.sentence

    return {
      "message" => params[:message],
      "timestamp" => params[:timestamp],
      "url" => params[:url],
      "id" => params[:id],
      "browserName" => "Chrome",
      "browserVersion" => "49.0.2623",
      "entry" => "window",
      "application" => params[:application],
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

  def trackjs_response(errors: 0, total_errors: 0, page: 1, page_size: 250)
    data = errors.times.map { trackjs_error }
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
