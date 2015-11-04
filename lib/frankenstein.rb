require 'frankenstein/cli'
require 'frankenstein/constants'
require 'frankenstein/date'
require 'frankenstein/emoji'
require 'frankenstein/github'
require 'frankenstein/io'
require 'frankenstein/log'
require 'frankenstein/network'
require 'frankenstein/output'
require 'frankenstein/usage'
require 'frankenstein/version'

# Check for live URLs on a page
module Frankenstein
  require 'colored'
  require 'json'
  require 'parallel'

  # logs are stored in FILE_LOG_DIRECTORY
  Dir.mkdir FILE_LOG_DIRECTORY unless File.exist?(FILE_LOG_DIRECTORY)

  # process cli arguments
  argv1, argv_flags = ARGV

  if argv1.nil?
    usage
    exit
  end

  option_github_stars_only = ARGV.include? OPTION_STARS
  option_log_to_file = ARGV.include? OPTION_LOG
  flag_control_failure = argv_flags.to_s.include? FLAG_FAIL
  flag_verbose = argv_flags.to_s.include? FLAG_VERBOSE

  log = Frankenstein::Log.new(flag_verbose, option_log_to_file)

  if argv1
    argv1_is_http = argv1.match(/^http/)

    unless argv1_is_http
      begin
        found_file_content = File.read(argv1)
      rescue StandardError => e
        log.verbose "Not a file: #{e.to_s.red}"
      end

      option_pull_request = if argv1.include? '/'
                              ARGV.include? OPTION_PULL_REQUEST
                            else
                              false
                            end
    end
  end

  flag_fetch_github_stars = cli_get_github option_github_stars_only, argv_flags

  flag_minimize_output = argv_flags.to_s.include? FLAG_MINIMIZE_OUTPUT
  if flag_minimize_output
    # TODO: remove this, not used
    log_number_of_items_per_row = cli_option_value OPTION_ROW, SEPARATOR, log
    log_number_of_items_per_row = DEFAULT_NUMBER_OF_ITEMS_PER_ROWS if
      log_number_of_items_per_row.nil?
  end

  number_of_threads = cli_option_value OPTION_THREADS, SEPARATOR, log
  number_of_threads = DEFAULT_NUMBER_OF_THREADS if number_of_threads.nil?
  log.verbose "Number of threads: #{number_of_threads}"

  option_white_list = cli_option_value_raw OPTION_WHITE_LIST, SEPARATOR, log
  m = "Option white list: #{option_white_list}"
  log.verbose m unless option_white_list.nil?

  option_head = ARGV.include? OPTION_HEAD

  if flag_fetch_github_stars || option_pull_request
    creds = github_netrc
    if creds.nil?
      error.log 'Missing GitHub credentials in .netrc'
      exit(1)
    end
  end

  # start
  elapsed_time_start = Time.now

  if option_log_to_file
    log.file_write "\n\nStart: #{elapsed_time_start} \n"
    log.file_write "Arguments: #{ARGV} \n"
  end

  if flag_minimize_output
    m = "Number of minimized output items / row: #{log_number_of_items_per_row}"
    log.verbose m
  end

  u, r = if argv1_is_http || found_file_content
           argv1
         else
           argv1_is_github_repo = argv1

           log.verbose 'Attempt to get default branch (unauthenticated)'

           # github api has a rate limit of 60 unauthenticated requests per hour
           # https://developer.github.com/v3/#rate-limiting
           json_url = GITHUB_API_BASE + 'repos/' + argv1_is_github_repo
           log.verbose "json url: #{json_url}"
           log.add "Finding default branch for #{argv1_is_github_repo.white}"

           body = net_get(json_url).body
           log.verbose body

           parsed = JSON.parse(body)
           message = parsed['message']
           message = '' if message.nil?
           log.verbose "Parsed message: #{message}"

           if message == 'Not Found' || message == 'Moved Permanently'
             m = "Retrieving repo #{argv1_is_github_repo} "
             log.error "#{m.red} #{message.downcase}"
             exit(1)
           elsif message.include? 'API rate limit exceeded'
             log.error "GitHub #{message}"
             log.add 'Finding readme...'

             default_branch = 'master'
             net_find_github_url_readme(argv1, default_branch)
           else
             default_branch = parsed['default_branch']
             log.add github_info(parsed, default_branch, argv1_is_github_repo)
             net_find_github_url_readme(argv1, default_branch)
           end # if message ==
         end # if message.include? "API..
  the_url = u
  readme = r
  log.verbose "Readme found: #{readme}"

  m = "#{em_logo} Processing links for ".white
  m << the_url.blue
  m << ' ...'.white
  log.add m

  content = if found_file_content
              found_file_content
            else
              code = net_status the_url
              log.verbose "#{the_url} status: #{code}"

              unless code == 200
                if argv1_is_http
                  log.error "url response (status code: #{code})"
                  exit(1)
                else
                  log.error 'could not find readme in master branch'.white
                  exit
                end
              end

              content = net_get(the_url).body
              content
            end
  File.open(FILE_TEMP, 'w') { |f| f.write(content) }
  links_found = URI.extract(content, /http()s?/)
  log.verbose "Links found: #{links_found}"

  links_to_check =
    links_found.reject { |x| x.length < 9 }
    .map { |x| x.gsub(/\).*/, '').gsub(/'.*/, '').gsub(/,.*/, '').gsub('/:', '/') }
    .uniq
  # ) for markdown
  # ' found on https://fastlane.tools/
  # , for link followed by comma
  # /: found on ircanywhere/ircanywhere

  links_to_check.unshift(CONTROLLED_ERROR) if flag_control_failure

  log.verbose '🔎  Links found: '.white
  log.verbose links_to_check

  if links_to_check.count == 0
    log.error_header 'no links found'
  else
    unless option_github_stars_only
      m = "🔎  Checking #{links_to_check.count} ".white
      m << pluralize('link', links_to_check.count).white
      m << ' (including a controlled failure)' if flag_control_failure
      log.add m
    end

    misc = []
    issues = []
    failures = []
    redirects = {}
    unless option_github_stars_only
      Parallel.each_with_index(links_to_check,
                               in_threads: number_of_threads) do |link|
        begin
          res = option_head ? net_head(link) : net_get(link)
        rescue StandardError => e
          log.error "Getting link #{link.white} #{e.message}"

          issue = "#{em_status_red} #{e.message} #{link}"
          issues.push(issue)
          failures.push(issue)
          next
        end

        if flag_minimize_output
          log.my_print status_glyph res.status, link, log
        else
          message = "#{status_glyph res.status, link, log} "\
                    "#{res.status == 200 ? '' : res.status} #{link}"
          log.add message
        end

        if res.status != 200
          m = "#{status_glyph res.status, link, log} #{res.status} #{link}"
          issues.push(m)

          if res.status >= 500
            misc.push(link)
          elsif res.status >= 400
            failures.push(link)
          elsif res.status >= 300
            # TODO: check white list
            redirect = resolve_redirects link, log
            log.verbose "#{link} was redirected to \n#{redirect}".yellow
            if redirect.nil?
              log.add "#{em_mad} No redirect found for #{link}"
            else
              redirects[link] = redirect unless
                in_white_list(link, option_white_list, log)
            end
          end # if res.status >= 500
        end # if res.status != 200
      end # Parallel

      if issues.count > 0
        percent = issues.count * 100 / links_to_check.count
        m = "#{issues.count} #{pluralize 'issue', issues.count} "\
            "(#{percent.round}%)"
        log.error_header m

        m = "   (#{issues.count} of #{links_to_check.count} "\
            "#{pluralize 'link', links_to_check.count})"
        log.add m

        log.add issues
      else
        m = "\n#{PRODUCT.white} #{'found no errors'.green} for "\
            "#{links_to_check.count} #{pluralize 'link', links_to_check.count}"\
            " #{em_sunglasses}"
        log.add m
      end

      if misc.count > 0
        message = "\n#{misc.count} misc. "\
                  "#{pluralize 'item', misc.count}: #{misc}"
        log.add message.white
      end
    end # if !option_github_stars_only

    if flag_fetch_github_stars
      github_repos = links_to_check.select { |link|
        link.to_s.downcase.include? 'github.com' and link.count('/') == 4
      }.map { |url| url.split('.com/')[1] }.reject { |x| x.include? '.' }.uniq
      log.verbose github_repos

      repos_info = []
      if github_repos.count == 0
        log.add 'No GitHub repos found'.white
      else
        m = "\n🔎  Getting information for #{github_repos.count} GitHub ".white
        log.my_print m
        log.add pluralize('repo', github_repos.count).white

        client = github_client
        Parallel.each_with_index(github_repos,
                                 in_threads: number_of_threads) do |repo|
          log.verbose "Attempting to get info for #{repo.white}"

          begin
            gh_repo = github_repo(client, repo)
          rescue StandardError => e
            log.error "Getting repo for #{repo.white} #{e.message.red}"
            next
          end

          count = gh_repo.stargazers_count
          pushed_at = gh_repo.pushed_at

          repo_updated = number_of_days_since pushed_at

          message = "#{em_star} #{count} #{repo} #{heat_index count} " if
            flag_fetch_github_stars
          message << repo_updated
          log.add message

          h = { repo: repo, count: count, pushed_at: pushed_at }
          repos_info.push(h)
        end # Parallel
        io_repo_log_json repos_info, log unless repos_info.count == 0
      end # if github_repos.count == 0
    end # flag_fetch_github_stars
  end # if links_to_check.count==0

  redirects = [] if redirects.nil?

  if redirects.count > 0
    message = "\n#{em_status_yellow} #{redirects.count} "\
              "#{pluralize 'redirect', redirects.count}"
    log.add message.yellow

    log.verbose "Replacing redirects in temp file #{FILE_TEMP}.."
    File.open(FILE_TEMP, 'a+') do |f|
      original = f.read
      replaced = original

      redirects.each do |key, array|
        log.add "#{key.yellow} redirects to \n#{array} \n\n"
        replaced = replaced.gsub key, array
      end # redirects.each

      File.open(FILE_TEMP, 'w') do |ff|
        log.add "Wrote redirects replaced to #{FILE_TEMP.white}"
        ff.write(replaced)
      end
    end # File.open(FILE_TEMP, 'a+') { |f|
  end # redirects.count

  log.add "Wrote log to #{FILE_LOG.white}" if option_log_to_file

  if option_pull_request
    m = 'Would you like to open a pull request to update the redirects? (y/n) '
    print m
    user_input = STDIN.gets.chomp

    if user_input.downcase == 'y'
      log.add "\nCreating pull request on GitHub for #{argv1} ...".white

      github = github_client

      repo = argv1
      forker = github_netrc_username
      fork = repo.gsub(%r{.*\/}, "#{forker}/")
      log.verbose "Fork: #{fork}"

      github_fork(github, repo)

      # check fork has been created
      forked_repo = nil
      while forked_repo
        sleep 1
        forked_repo = github_fork(github, "#{forker}/#{repo}")
        log.verbose 'forking repo.. sleep'
      end

      branch = default_branch

      ref = "heads/#{branch}"

      # commit to github via http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/
      sha_latest_commit = github.ref(fork, ref).object.sha
      sha_base_tree = github.commit(fork, sha_latest_commit).commit.tree.sha
      file_name = readme
      my_content = File.read(FILE_TEMP)

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

      head = "#{forker}:#{branch}"
      log.verbose "Set head to #{head}"

      created = github.create_pull_request(repo,
                                           branch,
                                           head,
                                           PULL_REQUEST_TITLE,
                                           PULL_REQUEST_DESCRIPTION)
      pull_link = created[:html_url].blue
      log.add "Pull request created: #{pull_link}".white
    end # user input
  end

  elapsed_seconds = Time.now - elapsed_time_start
  log.verbose "Elapsed time in seconds: #{elapsed_seconds}"
  log.my_print "\n🕐  Time elapsed: ".white
  case
  when elapsed_seconds > 60
    minutes = (elapsed_seconds / 60).floor
    seconds = elapsed_seconds - minutes * 60
    log.my_print "#{minutes.round(0)} #{pluralize 'minute', minutes} "
    log.add "#{seconds > 0 ? seconds.round(0).to_s << 's' : ''}"
  else
    log.add "#{elapsed_seconds.round(2)} #{pluralize 'second', elapsed_seconds}"
  end

  log.file_write "End: #{Time.new}" if option_log_to_file

  failures = [] if failures.nil?

  log.add ''
  if failures.count == 0
    log.add "#{em_logo} No failures for #{argv1.blue}".white
  else
    if (failures.count == 1) && (failures.include? CONTROLLED_ERROR)
      log.add "The only failure was the controlled failure #{em_sunglasses}"
    else
      message = "#{em_status_red} #{failures.count} "\
                "#{pluralize 'failure', failures.count} for #{argv1.blue}"
      log.add message.red
      exit(1)
    end
  end
end # module
