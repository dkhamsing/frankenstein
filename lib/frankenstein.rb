require 'frankenstein/cli'
require 'frankenstein/constants'
require 'frankenstein/date'
require 'frankenstein/github'
require 'frankenstein/logging'
require 'frankenstein/network'
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
  $option_log_to_file = ARGV.include? OPTION_LOG
  flag_control_failure = argv_flags.to_s.include? FLAG_FAIL
  $flag_verbose = argv_flags.to_s.include? FLAG_VERBOSE

  if argv1
    argv1_is_http = argv1.match(/^http/)

    unless argv1_is_http
      begin
        found_file_content = File.read(argv1)
      rescue StandardError => e
        verbose "Not a file: #{e.to_s.red}"
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
    log_number_of_items_per_row = cli_option_value OPTION_ROW, SEPARATOR
    log_number_of_items_per_row = DEFAULT_NUMBER_OF_ITEMS_PER_ROWS if
      log_number_of_items_per_row.nil?
  end

  $number_of_threads = cli_option_value OPTION_THREADS, SEPARATOR
  $number_of_threads = DEFAULT_NUMBER_OF_THREADS if $number_of_threads.nil?
  verbose "Number of threads: #{$number_of_threads}"

  option_white_list = cli_option_value_raw OPTION_WHITE_LIST, SEPARATOR
  verbose "Option white list: #{option_white_list}" unless option_white_list.nil?

  option_head = ARGV.include? OPTION_HEAD

  if flag_fetch_github_stars || option_pull_request
    creds = github_netrc
    if creds.nil?
      error_log 'Missing GitHub credentials in .netrc'
      exit(1)
    end
  end

  # start
  elapsed_time_start = Time.now

  if $option_log_to_file
    franken_log "\n\nStart: #{elapsed_time_start} \n"
    franken_log "Arguments: #{ARGV} \n"
  end

  if flag_minimize_output
    m = "Number of minimized output items / row: #{log_number_of_items_per_row}"
    verbose m
  end

  the_url = if argv1_is_http || found_file_content
              argv1
            else
              argv1_is_github_repo = argv1

              # note github api has a rate limit of 60 unauthenticated requests
              #   per hour https://developer.github.com/v3/#rate-limiting
              json_url = GITHUB_API_BASE + 'repos/' + argv1_is_github_repo
              f_puts "Finding default branch for #{argv1_is_github_repo.white}"
              verbose json_url

              body = net_get(json_url).body
              verbose body
              parsed = JSON.parse(body)

              message = parsed['message']
              verbose "Parsed message: #{message}"

              message = '' if message.nil?
              if message.include? 'API rate limit exceeded'
                error_log "GitHub #{message}"

                f_puts 'Finding readme...'
                default_branch = 'master'

                net_find_github_url(argv1, default_branch)
              else
                if message == 'Not Found' || message == 'Moved Permanently'
                  m = "#{em_mad} Error retrieving repo #{argv1_is_github_repo} "
                  f_print m.red
                  f_puts message.downcase
                  exit(1)
                end

                default_branch = parsed['default_branch']
                repo_description = parsed['description']
                repo_stars = parsed['stargazers_count']
                repo_pushed_at = parsed['pushed_at']

                repo_updated = number_of_days_since(Time.parse repo_pushed_at)
                m = "Found: #{default_branch.white} for "\
                      "#{argv1_is_github_repo} — "\
                      "#{repo_description} — #{repo_stars}#{em_star} "\
                      "— #{repo_updated}"
                f_puts m

                net_find_github_url(argv1, default_branch)
              end # if message ==
            end # if message.include? "API..

  f_print "#{em_logo} Processing links for ".white
  f_print the_url.blue
  f_puts ' ...'.white

  content = if found_file_content
              found_file_content
            else
              code = status the_url

              unless code == 200
                if argv1_is_http
                  error_log "url response (status code: #{code})"
                  exit(1)
                else
                  error_log 'could not find readme in master branch'.white
                  exit
                end
              end

              content = net_get(the_url).body
              content
            end
  File.open(FILE_TEMP, 'w') { |f| f.write(content) }
  links_found = URI.extract(content, /http()s?/)
  verbose "Links found: #{links_found}"

  links_to_check =
    links_found.reject { |x| x.length < 9 }
    .map { |x| x.gsub(/\).*/, '').gsub(/'.*/, '').gsub(/,.*/, '') }
    .uniq
  # ) for markdown
  # ' found on https://fastlane.tools/
  # , for link followed by comma

  links_to_check.unshift(CONTROLLED_ERROR) if flag_control_failure

  verbose '🔎  Links found: '.white
  verbose links_to_check

  if links_to_check.count == 0
    error_result_header 'no links found'
  else
    unless option_github_stars_only
      f_print "🔎  Checking #{links_to_check.count} ".white
      f_puts pluralize('link', links_to_check.count).white

      f_puts '   (including a controlled failure)' if flag_control_failure
    end

    misc = []
    issues = []
    failures = []
    redirects = {}
    unless option_github_stars_only
      Parallel.each_with_index(links_to_check,
                               in_threads: $number_of_threads) do |link, index|
        begin
          res = option_head ? net_head(link) : net_get(link)
        rescue StandardError => e
          error_log "Getting link #{link.white} #{e.message}"

          issue = "#{em_status_red} #{e.message} #{link}"
          issues.push(issue)
          failures.push(issue)
          next
        end

        if flag_minimize_output
          f_print status_glyph res.status, link
          if ((index + 1) % log_number_of_items_per_row == 0) && $number_of_threads == 0
            n = log_number_of_items_per_row *
                (1 + (index / log_number_of_items_per_row))
            f_puts " #{n}"
          end
        else
          message = "#{status_glyph res.status, link} "\
                    "#{res.status == 200 ? '' : res.status} #{link}"
          f_puts_with_index index + 1, links_to_check.count, message
        end

        if res.status != 200
          issues.push("#{status_glyph res.status, link} #{res.status} #{link}")

          if res.status >= 500
            misc.push(link)
          elsif res.status >= 400
            failures.push(link)
          elsif res.status >= 300
            # TODO: check white list
            redirect = resolve_redirects link
            verbose "#{link} was redirected to \n#{redirect}".yellow
            if redirect.nil?
              f_puts "#{em_mad} No redirect found for #{link}"
            else
              redirects[link] = redirect unless in_white_list(link, option_white_list)
            end
          end # if res.status >= 500
        end # if res.status != 200
      end # Parallel

      if issues.count > 0
        percent = issues.count * 100 / links_to_check.count
        m = "#{issues.count} #{pluralize 'issue', issues.count} "\
            "(#{percent.round}%)"
        error_result_header m

        m = "   (#{issues.count} of #{links_to_check.count} "\
            "#{pluralize 'link', links_to_check.count})"
        f_puts m

        f_puts issues
      else
        m = "\n#{PRODUCT.white} #{'found no errors'.green} for "\
            "#{links_to_check.count} #{pluralize 'link', links_to_check.count}"\
            " #{em_sunglasses}"
        f_puts m
      end

      if misc.count > 0
        message = "\n#{misc.count} misc. "\
                  "#{pluralize 'item', misc.count}: #{misc}"
        f_puts message.white
      end
    end # if !option_github_stars_only

    if flag_fetch_github_stars
      github_repos = links_to_check.select { |link|
        link.to_s.downcase.include? 'github.com' and link.count('/') == 4
      }.map { |url| url.split('.com/')[1] }.reject { |x| x.include? '.' }.uniq
      verbose github_repos

      repos_info = []
      if github_repos.count == 0
        f_puts 'No GitHub repos found'.white
      else
        f_print "\n🔎  "
        f_print "Getting information for #{github_repos.count} GitHub ".white
        f_puts pluralize('repo', github_repos.count).white

        client = github_client
        Parallel.each_with_index(github_repos,
                                 in_threads: $number_of_threads) do |repo, idx|
          verbose "Attempting to get info for #{repo.white}"

          begin
            gh_repo = github_repo(client, repo)
          rescue StandardError => e
            error_log "Getting repo for #{repo.white} #{e.message.red}"
            next
          end

          count = gh_repo.stargazers_count
          pushed_at = gh_repo.pushed_at

          repo_updated = number_of_days_since pushed_at

          message = "#{em_star} #{count} #{repo} #{heat_index count} " if
            flag_fetch_github_stars
          message << repo_updated
          f_puts_with_index idx + 1, github_repos.count, message

          h = { repo: repo, count: count, pushed_at: pushed_at }
          repos_info.push(h)
        end # Parallel
        repo_log_json repos_info unless repos_info.count == 0
      end # if github_repos.count == 0
    end # flag_fetch_github_stars
  end # if links_to_check.count==0

  redirects = [] if redirects.nil?

  if redirects.count > 0
    message = "\n#{em_status_yellow} #{redirects.count} "\
              "#{pluralize 'redirect', redirects.count}"
    f_puts message.yellow

    verbose "Replacing redirects in temp file #{FILE_TEMP}.."
    File.open(FILE_TEMP, 'a+') do |f|
      original = f.read
      replaced = original

      redirects.each do |key, array|
        f_puts "#{key.yellow} redirects to \n#{array} \n\n"
        replaced = replaced.gsub key, array
      end # redirects.each

      File.open(FILE_TEMP, 'w') do |ff|
        f_puts "Wrote redirects replaced to #{FILE_TEMP.white}"
        ff.write(replaced)
      end
    end # File.open(FILE_TEMP, 'a+') { |f|
  end # redirects.count

  f_puts "Wrote log to #{FILE_LOG.white}" if $option_log_to_file

  if option_pull_request
    print 'Would you like to open a pull request? (y/n) '
    user_input = STDIN.gets.chomp

    if user_input.downcase == 'y'
      f_puts "\nCreating pull request on GitHub for #{argv1} ...".white

      github = github_client

      repo = argv1
      forker = github_netrc_username
      fork = repo.gsub(%r{.*\/}, "#{forker}/")
      verbose "Fork: #{fork}"

      github_fork(github, repo)

      # check fork has been created
      forked_repo = nil
      while forked_repo
        sleep 1
        forked_repo = github_fork(github, "#{forker}/#{repo}")
        verbose "forking repo.. sleep"
      end

      branch = default_branch

      ref = "heads/#{branch}"

      # commit to github via http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/
      sha_latest_commit = github.ref(fork, ref).object.sha
      sha_base_tree = github.commit(fork, sha_latest_commit).commit.tree.sha
      file_name = $readme
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
      verbose "Updated ref: #{updated_ref}"
      verbose "Sent commit to fork #{fork}"

      head = "#{forker}:#{branch}"
      verbose "Set head to #{head}"

      created = github.create_pull_request(repo,
                                           branch,
                                           head,
                                           PULL_REQUEST_TITLE,
                                           PULL_REQUEST_DESCRIPTION)
      pull_link = created[:html_url].blue
      f_puts "Pull request created: #{pull_link}".white
    end # user input
  end

  elapsed_seconds = Time.now - elapsed_time_start
  verbose "Elapsed time in seconds: #{elapsed_seconds}"
  f_print "\n🕐  Time elapsed: ".white
  case
  when elapsed_seconds > 60
    minutes = (elapsed_seconds / 60).floor
    seconds = elapsed_seconds - minutes * 60
    f_print "#{minutes.round(0)} #{pluralize 'minute', minutes} "
    f_puts "#{seconds > 0 ? seconds.round(0).to_s << 's' : ''}"
  else
    f_puts "#{elapsed_seconds.round(2)} #{pluralize 'second', elapsed_seconds}"
  end

  franken_log "End: #{Time.new}" if $option_log_to_file

  failures = [] if failures.nil?

  f_puts ''
  if failures.count == 0
    f_puts "#{em_logo} No failures for #{argv1.blue}".white
  else
    if (failures.count == 1) && (failures.include? CONTROLLED_ERROR)
      f_puts "The only failure was the controlled failure #{em_sunglasses}"
    else
      message = "#{em_status_red} #{failures.count} "\
                "#{pluralize 'failure', failures.count} for #{argv1.blue}"
      f_puts message.red
      exit(1)
    end
  end
end # module
