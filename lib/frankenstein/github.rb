# GitHub helper
module Frankenstein
  class << self
    require 'octokit'
    require 'netrc'

    def github_client
      Octokit::Client.new(netrc: true)
    end

    def github_fork(client, repo)
      client.fork(repo)
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
