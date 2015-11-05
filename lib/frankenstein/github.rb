# GitHub helper
module Frankenstein
  GITHUB_API_BASE = 'https://api.github.com/'
  GITHUB_RAW_CONTENT_URL = 'https://raw.githubusercontent.com/'

  NETRC_GITHUB_MACHINE = 'api.github.com'

  class << self
    require 'octokit'
    require 'netrc'
    require 'json'

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

    def github_pull_request(github, repo, branch, readme, filename, log)
      forker = github_netrc_username
      fork = repo.gsub(%r{.*\/}, "#{forker}/")
      log.verbose "Fork: #{fork}"

      github_fork(github, repo)

      # check fork has been created
      forked_repo = nil
      while forked_repo
        sleep 2
        forked_repo = github_fork(github, fork)
        log.verbose 'Forking repo.. sleep'
      end

      # commit change
      ref = "heads/#{branch}"

      # commit to github via http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/
      sha_latest_commit = github.ref(fork, ref).object.sha
      sha_base_tree = github.commit(fork, sha_latest_commit).commit.tree.sha
      file_name = readme
      my_content = File.read(filename)

      blob_sha = github.create_blob(fork, Base64.encode64(my_content), 'base64')
      sha_new_tree = github.create_tree(fork,
                                        [{ path: file_name,
                                           mode: '100644',
                                           type: 'blob',
                                           sha: blob_sha }],
                                        base_tree: sha_base_tree).sha
      commit_message = PULL_REQUEST_TITLE
      sha_new_commit = github.create_commit(fork,
                                            commit_message,
                                            sha_new_tree,
                                            sha_latest_commit).sha
      updated_ref = github.update_ref(fork, ref, sha_new_commit)
      log.verbose "Updated ref: #{updated_ref}"
      log.verbose "Sent commit to fork #{fork}"

      # create pull request
      head = "#{forker}:#{branch}"
      log.verbose "Set head to #{head}"

      created = github.create_pull_request(repo,
                                           branch,
                                           head,
                                           PULL_REQUEST_TITLE,
                                           PULL_REQUEST_DESCRIPTION)
      created[:html_url].blue
    end

    def github_repo(client, repo)
      client.repo(repo)
    end

    def github_repo_info(gh_repo, name)
      count = gh_repo.stargazers_count
      pushed_at = gh_repo.pushed_at
      repo_updated = number_of_days_since pushed_at
      message = "#{em_star} #{count} #{name} #{heat_index count} "
      message << repo_updated

      h = { repo: name, count: count, pushed_at: pushed_at }

      [message, h]
    end

    def github_repo_json_info(parsed, default_branch, argv1_is_github_repo)
      repo_description = parsed['description']
      repo_stars = parsed['stargazers_count']
      repo_pushed_at = parsed['pushed_at']
      repo_updated = number_of_days_since(Time.parse repo_pushed_at)

      "Found: #{default_branch.white} for "\
        "#{argv1_is_github_repo} — "\
        "#{repo_description} — #{repo_stars}#{em_star} "\
        "— #{repo_updated}"
    end

    def github_repo_unauthenticated(argv1, log)
      # github api has a rate limit of 60 unauthenticated requests per hour
      # https://developer.github.com/v3/#rate-limiting
      json_url = GITHUB_API_BASE + 'repos/' + argv1
      log.verbose "Endpoint: #{json_url}"
      log.add "Finding default branch for #{argv1.white}"

      body = net_get(json_url).body
      log.verbose body

      parsed = JSON.parse(body)
      message = parsed['message']
      message = '' if message.nil?

      [message, parsed]
    end

    def github_repos_info(github_repos, number_of_threads, client, log)
      repos_info = []
      Parallel.each(github_repos, in_threads: number_of_threads) do |repo|
        log.verbose "Attempting to get info for #{repo.white}"

        begin
          gh_repo = github_repo(client, repo)
        rescue StandardError => e
          log.error "Getting repo for #{repo.white} #{e.message.red}"
          next
        end

        m, hash = github_repo_info(gh_repo, repo)
        repos_info.push(hash)
        log.add m
        log.verbose "   #{gh_repo.description}"
      end

      io_repo_log_json(repos_info, log) unless repos_info.count == 0
    end
  end # class
end
