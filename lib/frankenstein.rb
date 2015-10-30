require 'frankenstein/cli'
require 'frankenstein/constants'
require 'frankenstein/date'
require 'frankenstein/logging'
require 'frankenstein/usage'
require 'frankenstein/version'

# Check for live URLs on a page
module Frankenstein
  require 'colored'
  require 'faraday'
  require 'faraday_middleware'
  require 'json'
  require 'parallel'

  # github
  require 'octokit'
  require 'netrc'

  # logs are stored in logs/
  logs_dir = 'logs'
  Dir.mkdir logs_dir unless File.exist?(logs_dir)

  # process cli arguments
  argv1, argv_flags = ARGV

  option_github_stars_only = ARGV.include? OPTION_STARS
  option_github_last_push = ARGV.include? OPTION_LAST_PUSH
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

  flag_fetch_github_stars = if option_github_stars_only
                              true
                            else
                              argv_flags.to_s.include? FLAG_GITHUB_STARS
                            end

  flag_minimize_output = argv_flags.to_s.include? FLAG_MINIMIZE_OUTPUT
  if flag_minimize_output
    log_number_of_items_per_row = option_value OPTION_ROW, SEPARATOR
    log_number_of_items_per_row = DEFAULT_NUMBER_OF_ITEMS_PER_ROWS if
      log_number_of_items_per_row.nil?
  end

  $number_of_threads = option_value OPTION_THREADS, SEPARATOR
  $number_of_threads = DEFAULT_NUMBER_OF_THREADS if $number_of_threads.nil?
  verbose "Number of threads: #{$number_of_threads}"

  if flag_fetch_github_stars || option_pull_request || option_github_last_push
    n = Netrc.read
    creds = n[NETRC_GITHUB_MACHINE]
    if creds.nil?
      f_puts "#{mad} Error: missing GitHub credentials in .netrc".red
      exit(1)
    end
  end

  if argv1.nil?
    usage
    exit(0)
  end

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
      return nil
    end
  end # class

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

    # note github api has a rate limit of 60 unauthenticated requests per hour https://developer.github.com/v3/#rate-limiting
    json_url = GITHUB_API_BASE + 'repos/' + argv1_is_github_repo
    f_puts "Finding default branch for #{argv1_is_github_repo.white}"
    verbose json_url

    body = Faraday.get(json_url).body
    verbose body
    parsed = JSON.parse(body)

    message = parsed['message']
    verbose "Parsed message: #{message}"

    message = '' if message.nil?

    if message.include? 'API rate limit exceeded'
      f_puts "#{mad} Error: GitHub #{message}".red

      f_puts 'Finding readme...'
      default_branch = 'master'
      base = "https://raw.githubusercontent.com/#{argv1}/#{default_branch}/"
      "#{base}#{
        README_VARIATIONS.find do |x|
          temp = "#{base}#{x}"
          $readme = x
          verbose "Readme found: #{$readme}"
          status(temp) < 400
        end
      }"
    else
      if message == 'Not Found'
        f_puts "#{mad} Error retrieving repo #{argv1_is_github_repo}".red
        exit 1
      end

      default_branch = parsed['default_branch']
      repo_description = parsed['description']
      repo_stars = parsed['stargazers_count']
      repo_pushed_at = parsed['pushed_at']

      repo_updated = number_of_days_since(Time.parse repo_pushed_at)
      message = "Found: #{default_branch.white} for #{argv1_is_github_repo} — "\
                "#{repo_description} — #{repo_stars}⭐️  — #{repo_updated}"
      f_puts message

      base = "https://raw.githubusercontent.com/#{argv1}/#{default_branch}/"
      the_url = "#{base}#{
          README_VARIATIONS.find do |x|
            temp = "#{base}#{x}"
            $readme = x
            verbose "Readme found: #{$readme}"
            status(temp) < 400
          end
          }"
    end # if message ==
  end # if message.include? "API..

  f_print "#{logo} Processing links for ".white
  f_print the_url.blue
  f_puts ' ...'.white

  links_found = if found_file_content
                  URI.extract(found_file_content, /http()s?/)
                else
                  code = status the_url

                  unless code == 200
                    if argv1_is_http
                      error_message = 'url response'
                      m = "#{mad} Error, #{error_message.red} "\
                          "(status code: #{code.to_s.red})"
                      f_puts m
                      exit 1
                    else
                      error_message = 'could not find readme in master branch'
                      m = "#{logo} Error, #{error_message.white} "
                      f_puts m
                      exit
                    end
                  end

                  res = Faraday.get(the_url)
                  content = res.body
                  File.open(FILE_TEMP, 'w') { |f| f.write(content) }
                  URI.extract(content, /http()s?/)
                end
  verbose "Links found: #{links_found}"

  links_to_check = links_found.reject { |x| x.length < 9 }
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
          res = Faraday.get(link)
        rescue StandardError => e
          f_print "#{mad} Error getting link "
          f_print link.white
          f_puts ": #{e.message.red}"

          issue = "#{status_red} #{e.message} #{link}"
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
            redirect = resolve_redirects link
            verbose "#{link} was redirected to \n#{redirect}".white
            if redirect.nil?
              f_puts "#{mad} No redirect found for #{link}"
            else
              redirects[link] = redirect
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
        m = "#{"\nfrankenstein".white} #{'found no errors'.green} for "\
            "#{links_to_check.count} #{pluralize 'link', links_to_check.count}"\
            " #{sunglasses}"
        f_puts m
      end

      if misc.count > 0
        message = "\n#{misc.count} misc. "\
                  "#{pluralize 'item', misc.count}: #{misc}"
        f_puts message.white
      end
    end # if !option_github_stars_only

    if flag_fetch_github_stars || option_github_last_push
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

        client = Octokit::Client.new(netrc: true)
        Parallel.each_with_index(github_repos,
                                 in_threads: $number_of_threads) do |repo, idx|
          verbose "Attempting to get stars for #{repo}"

          begin
            gh_repo = client.repo(repo)
          rescue StandardError => e
            f_print "#{mad} Error getting repo for "
            f_print repo.white
            f_puts ": #{e.message.red}"
            next
          end

          count = gh_repo.stargazers_count
          pushed_at = gh_repo.pushed_at

          repo_updated = number_of_days_since pushed_at

          message = "⭐️  #{count} #{repo} #{heat_index count} " if flag_fetch_github_stars
          message << repo_updated if option_github_last_push
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
    message = "\n#{status_yellow} #{redirects.count} "\
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

      github = Octokit::Client.new(netrc: true)

      repo = argv1
      forker = Netrc.read[NETRC_GITHUB_MACHINE][0]
      fork = repo.gsub(%r{.*\/}, "#{forker}/")
      verbose "Fork: #{fork}"

      github.fork(repo)

      sleep 2 # give it time to create repo :-(

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

      github.delete_repository(fork)
      verbose 'Deleted fork'

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
    f_puts "#{logo} No failures for #{argv1.blue}".white
  else
    if (failures.count == 1) && (failures.include? CONTROLLED_ERROR)
      f_puts "The only failure was the controlled failure #{sunglasses}"
    else
      message = "#{status_red} #{failures.count} "\
                "#{pluralize 'failure', failures.count} for #{argv1.blue}"
      f_puts message.red
      exit(1)
    end
  end
end # module
