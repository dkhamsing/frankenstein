# Networking
module Frankenstein
  class << self
    def net_find_github_url_readme(repo, branch)
      base = "#{GITHUB_RAW_CONTENT_URL}#{repo}/#{branch}/"
      readme = README_VARIATIONS.find do |x|
        temp = "#{base}#{x}"
        net_status(temp) == 200
      end
      url = "#{base}#{readme}"

      [url, readme]
    end
  end # class
end
