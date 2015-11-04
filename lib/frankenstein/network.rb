# Networking
module Frankenstein
  require 'faraday'
  require 'faraday_middleware'

  class << self
    def net_head(url)
      Faraday.head(url)
    end

    def net_get(url)
      Faraday.get(url)
    end

    def status(url, log)
      response = net_head(url)
      code = response.status
      log.verbose "Status: #{code} #{url}"
      code
    end

    def resolve_redirects(url, log) # modified via http://stackoverflow.com/questions/5532362/how-do-i-get-the-destination-url-of-a-shortened-url-using-ruby/20818142#20818142
      response = fetch_response(log, url, method: :head)
      if response
        return response.to_hash[:url].to_s
      else
        return nil
      end
    end

    def fetch_response(log, url, method: :get)
      conn = Faraday.new do |b|
        b.use FaradayMiddleware::FollowRedirects
        b.adapter :net_http
      end
      return conn.send method, url
    rescue Faraday::Error, Faraday::Error::ConnectionFailed => e
      log.verbose "fetch_response error #{e}"
      return nil
    end

    def net_find_github_url_readme(repo, branch, log)
      base = "#{GITHUB_RAW_CONTENT_URL}#{repo}/#{branch}/"
      readme = nil
      url = "#{base}#{
        README_VARIATIONS.find do |x|
          readme = x
          log.verbose "Readme found: #{readme}"

          temp = "#{base}#{x}"
          status(temp, log) < 400
        end
      }"
      return url, readme
    end
  end # class
end
