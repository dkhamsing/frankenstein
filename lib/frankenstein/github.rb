# GitHub helper
module Frankenstein
  GITHUB_API_BASE = 'https://api.github.com/'
  GITHUB_RAW_CONTENT_URL = 'https://raw.githubusercontent.com/'

  GITHUB_CREDS_ERROR = 'Missing GitHub credentials in .netrc'

  NETRC_GITHUB_MACHINE = 'api.github.com'

  class << self
    require 'octokit'
    require 'netrc'
    require 'json'
    require 'github-readme'

    require 'frankenstein/date'
    require 'frankenstein/diff'
    require 'frankenstein/emoji'
    # require 'pp'

    def github_client
      Octokit::Client.new(netrc: true)
    end

    def github_create_gist(file, public)
      separator = '/'
      filename = file.split(separator)[1] if file.include? separator

      puts "🏃 Creating a gist for #{filename.white}"

      gputs 'Reading content'
      c = File.read(file)
      c = c.gsub('[34m', '').gsub('[0m', '').gsub('[37m', '').gsub('[32m', '')
          .gsub('[33m', '').gsub('[31m', '')

      gputs 'Creating GitHub client'
      client = github_client
      gist_file_name = filename.split('-')[4..-1].join '-'
      payload = { public: public,
                  files: { gist_file_name => { content: c } }
                }

      gputs 'Client creating gist'
      r = client.create_gist(payload)

      html_url = r[:html_url]
      gputs "🎉 gist created: #{html_url.white}"

      [html_url, filename]
    end

    def github_default_branch(client, repo)
      r = github_repo client, repo
      r['default_branch']
    end

    def github_fork(client, repo)
      client.fork(repo)
    end

    def github_netrc
      n = Netrc.read
      n[NETRC_GITHUB_MACHINE]
    end

    def github_creds
      !(github_netrc.nil?)
    end

    def github_issues(client, state, page = nil)
      q = "is:#{state} is:pr author:#{github_netrc_username}"

      if page.nil?
        client.search_issues q
      else
        client.search_issues q, per_page: page
      end
    end

    def github_netrc_username
      n = github_netrc
      n[0]
    end

    def github_pull_heading(kind)
      r = "\n\n### #{kind}Corrected URLs \n"\
          "Was | Now \n"\
          "--- | --- \n"
      r
    end

    MATCH = '://github'
    def github_pull_description(redirects, _)
      pr_desc = PULL_REQUEST_DESCRIPTION

      # sort by url
      redirects = redirects.uniq.sort_by { |r| r.keys[0] }

      https, redirects = redirects.partition do |hash|
        original, redirect = hash.first
        changes = Differ.diff_by_word(redirect, original).changes
        c = changes[0]
        next if changes.count > 1
        next if c.class == NilClass
        (c.delete == 'http') && (c.insert == 'https')
      end

      github, rest =
        redirects.partition { |r| r.keys[0].downcase.include? MATCH }
      if github.count > 0
        h = github_pull_heading 'GitHub '
        pr_desc << h

        github.each do |hash|
          key, array = hash.first
          pr_desc << "#{key} | #{array} \n" unless key == array
        end
      end

      if https.count > 0
        h = github_pull_heading 'HTTPS '
        pr_desc << h

        https.each do |hash|
          key, array = hash.first
          pr_desc << "#{key} | #{array} \n" unless key == array
        end
      end

      if rest.count > 0
        h = if (https.count == 0) && (github.count == 0)
              github_pull_heading ''
            else
              github_pull_heading 'Other '
            end

        pr_desc << h

        rest.each do |hash|
          key, array = hash.first
          pr_desc << "#{key} | #{array} \n" unless key == array
        end
      end

      # commented out because failures are not always correct when using
      # head requests

      # if failures.count > 0
      #   pr_desc << "\n### URLS could not be reached\n"
      #   failures.each do |y|
      #     pr_desc << "\n - #{y}"
      #     # puts y
      #   end
      # end

      pr_desc
    end

    def github_pull_request(repo, branch, readme, filename, description, log)
      forker = github_netrc_username
      fork = repo.gsub(%r{.*\/}, "#{forker}/")
      log.verbose "Fork: #{fork}"

      github = github_client

      # fork
      puts "Forking to #{fork.white}..."
      forked_repo = nil
      while forked_repo.nil?
        forked_repo = github_fork(github, repo)
        sleep 2
        log.verbose 'Forking repo.. sleep'
      end

      # commit change
      puts 'Committing change...'
      ref = "heads/#{branch}"

      # commit to github via http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/
      puts '(Getting ref...)'
      begin
        githubref = github.ref(fork, ref)

      rescue StandardError => e
        puts "Error: #{e}".red
        delay = 3
        puts "Trying again in #{delay} seconds...".red
        sleep delay
        githubref = github.ref(fork, ref)
      end

      sha_latest_commit = githubref.object.sha
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
      commit_message = PULL_REQUEST_COMMIT_MESSAGE
      sha_new_commit = github.create_commit(fork,
                                            commit_message,
                                            sha_new_tree,
                                            sha_latest_commit).sha
      updated_ref = github.update_ref(fork, ref, sha_new_commit)
      log.verbose "Updated ref: #{updated_ref}"
      log.verbose "Sent commit to fork #{fork}"

      # create pull request
      puts 'Opening pull request...'
      head = "#{forker}:#{branch}"
      log.verbose "Set head to #{head}"

      begin
        created = github.create_pull_request(repo,
                                             branch,
                                             head,
                                             PULL_REQUEST_TITLE,
                                             description)
        return created[:html_url]
      rescue StandardError => e
        puts 'Could not create pull request'.red
        puts "error #{e}".red
        return nil
      end
    end

    def github_readme(client, repo)
      r = GitHubReadme::get repo, client

      e = r['error']
      return [nil, e] unless e.nil?

      name = r['name']
      readme = r['readme']
      [name, readme]
    end

    def github_readme_unauthenticated(argv1, log)
      json_url = GITHUB_API_BASE + 'repos/' + argv1 + '/readme'
      log.verbose "Endpoint: #{json_url}"
      log.add "Finding readme for #{argv1.white}"

      body = net_get(json_url).body
      log.verbose body

      parsed = JSON.parse(body)
      # pp parsed
      readme = parsed['name']
      url = parsed['download_url']
      content = parsed['content']

      decoded = Base64.decode64 content unless content.nil?

      # TODO: this could run out of api calls.. ?

      [url, readme, decoded]
    end

    def github_repo(client, repo)
      client.repo(repo)
    end

    def github_repo_error(message)
      message == 'Not Found' || message == 'Moved Permanently'
    end

    def github_repo_error_message(message, argv1)
      m = "Retrieving repo #{argv1} "
      "#{m.red} #{message.downcase}"
    end

    def github_repo_info_client(client, repo, default_branch)
      parsed = github_repo client, repo

      repo_description = parsed['description']
      repo_stars = parsed['stargazers_count']
      repo_pushed_at = parsed['pushed_at'].to_s
      puts repo_pushed_at

      _, days = number_of_days_since_raw(Time.parse repo_pushed_at)

      raw_updated = if days == 0
                      'today'
                    else
                      "#{pluralize2 days, 'day'} ago"
                    end
      raw = {
        description: repo_description,
        stars: repo_stars,
        pushed_at: repo_pushed_at,
        updated: raw_updated
      }

      repo_updated = number_of_days_since(Time.parse repo_pushed_at)

      m = "Found: #{default_branch.white} for "\
          "#{repo} — "\
          "#{repo_description} — #{repo_stars}#{em_star} "\
          "— #{repo_updated}"
      [m, raw]
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
      _, days = number_of_days_since_raw(Time.parse repo_pushed_at)

      raw_updated = if days == 0
                      'today'
                    else
                      "#{pluralize2 days, 'day'} ago"
                    end
      raw = {
        description: repo_description,
        stars: repo_stars,
        pushed_at: repo_pushed_at,
        updated: raw_updated
      }

      repo_updated = number_of_days_since(Time.parse repo_pushed_at)

      m = "Found: #{default_branch.white} for "\
          "#{argv1_is_github_repo} — "\
          "#{repo_description} — #{repo_stars}#{em_star} "\
          "— #{repo_updated}"
      [m, raw]
    end

    def github_repo_exist(client, repo)
      client.repository?(repo)
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

    def github_get_repos(l)
      gmatch = 'github.com'
      l.select { |m| (m.to_s.downcase.include? gmatch) && (m.count('/') == 4) }
        .map { |url| url.split('.com/')[1] }
        .reject { |x| (x.include? '.') || (x.include? '#') }
        .uniq
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

    def gputs(m)
      puts "  #{m}"
    end
  end # class
end
