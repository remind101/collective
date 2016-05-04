require 'securerandom'

module TrackJSHelpers
  def trackjs_error(params = {
    message: nil,
    timestamp: Time.now.strftime("%FT%T%:z"),
    url: "https://www.remind.com",
    application: "r101-frontend",
    id: SecureRandom.hex
  })
    p "params"
    pp params
    trackJsUrl = "https://my.trackjs.com/details/#{params[:id]}"
    params[:message] ||= "stuff"

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
      "trackJsUrl" => trackJsUrl,
      "isStarred" => false
    }
  end

  def trackjs_metadata(totalCount = 0, page = 1, pageSize = 250, hasMore = true)
    return {
      "totalCount" => totalCount,
      "page" => page,
      "size" => pageSize,
      "hasMore" => hasMore,
      "trackJsUrl" => "https://my.trackjs.com/recent?"
    }
  end

  def trackjs_response(errors = 0, page = 1, pageSize = 250, hasMore = true)
    data = []
    errors.times do
      data.push(trackjs_error)
    end

    return {
      "data" => data,
      "metadata" => trackjs_metadata(data.length, page, pageSize, hasMore)
    }
  end
end

RSpec.configure do |config|
  config.include TrackJSHelpers
end
