# Networking
module Frankenstein
  class << self
    def status(url)
      response = Faraday.head(url)
      code = response.status
      verbose "Status: #{code} #{url}"
      code
    end

    def resolve_redirects(url) # resolve_redirects via http://stackoverflow.com/questions/5532362/how-do-i-get-the-destination-url-of-a-shortened-url-using-ruby/20818142#20818142
      response = fetch_response(url, method: :head)
      if response
        return response.to_hash[:url].to_s
      else
        return nil
      end
    end

    def fetch_response(url, method: :get)
      conn = Faraday.new do |b|
        b.use FaradayMiddleware::FollowRedirects
        b.adapter :net_http
      end
      return conn.send method, url
    rescue Faraday::Error, Faraday::Error::ConnectionFailed => e
      verbose "fetch_response error #{e}"
      return nil
    end

    def find_url(repo, branch)
      base = "#{GITHUB_RAW_CONTENT_URL}#{repo}/#{branch}/"
      "#{base}#{
        README_VARIATIONS.find do |x|
          temp = "#{base}#{x}"
          $readme = x
          verbose "Readme found: #{$readme}"
          status(temp) < 400
        end
      }"
    end
  end # class
end
