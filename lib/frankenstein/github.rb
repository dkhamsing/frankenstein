# GitHub helper
module Frankenstein
  GITHUB_API_BASE = 'https://api.github.com/'
  GITHUB_RAW_CONTENT_URL = 'https://raw.githubusercontent.com/'

  NETRC_GITHUB_MACHINE = 'api.github.com'

  class << self
    require 'octokit'
    require 'netrc'

    def github_client
      Octokit::Client.new(netrc: true)
    end

    def github_fork(client, repo)
      client.fork(repo)
    end

    def github_info(parsed, default_branch, argv1_is_github_repo)
      repo_description = parsed['description']
      repo_stars = parsed['stargazers_count']
      repo_pushed_at = parsed['pushed_at']
      repo_updated = number_of_days_since(Time.parse repo_pushed_at)

      "Found: #{default_branch.white} for "\
        "#{argv1_is_github_repo} — "\
        "#{repo_description} — #{repo_stars}#{em_star} "\
        "— #{repo_updated}"
    end

    def github_netrc
      n = Netrc.read
      n[NETRC_GITHUB_MACHINE]
    end

    def github_netrc_username
      n = github_netrc
      n[0]
    end

    def github_repo(client, repo)
      client.repo(repo)
    end
  end # class
end
