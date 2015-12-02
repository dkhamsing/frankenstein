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

    def net_find_github_url_readme(repo, branch)
      base = "#{GITHUB_RAW_CONTENT_URL}#{repo}/#{branch}/"
      readme = README_VARIATIONS.find do |x|
        temp = "#{base}#{x}"
        net_status(temp) == 200
      end
      url = "#{base}#{readme}"

      [url, readme]
    end

    def net_status(url)
      response = net_head(url)
      code = response.status
      # log.verbose "Status: #{code} #{url}"
      code
    end

    # modified via http://stackoverflow.com/questions/5532362/how-do-i-get-the-destination-url-of-a-shortened-url-using-ruby/20818142#20818142
    def net_resolve_redirects(url, log)
      response = fetch_response(log, url, method: :head)
      if response
        r = response.to_hash[:url].to_s

        # handle anchor
        r << url.match('#.*')[0] if url.include? '#'

        return r
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
  end # class
end
