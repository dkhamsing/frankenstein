require 'frankenstein/cli'
require 'frankenstein/constants'
require 'frankenstein/date'
require 'frankenstein/emoji'
require 'frankenstein/github'
require 'frankenstein/io'
require 'frankenstein/log'
require 'frankenstein/network'
require 'frankenstein/output'
require 'frankenstein/twitter'
require 'frankenstein/usage'
require 'frankenstein/version'

# Check for live URLs on a page
module Frankenstein
  require 'colored'
  require 'parallel'

  # logs are stored in FILE_LOG_DIRECTORY
  Dir.mkdir FILE_LOG_DIRECTORY unless File.exist?(FILE_LOG_DIRECTORY)

  # process cli arguments
  argv1, argv_flags = ARGV

  if argv1.nil?
    usage
    exit
  end

  flag_verbose = cli_log(argv_flags)
  log = Frankenstein::Log.new(flag_verbose, argv1)

  file_copy = log.filename(FILE_COPY)
  file_updated = log.filename(FILE_UPDATED)
  file_redirects = log.filename(FILE_REDIRECTS)
  file_log = log.filelog

  argv1 = cli_filter_github(argv1)

  option_github_stars_only,
  option_head,
  option_pull_request,
  option_white_list,
  flag_control_failure,
  flag_fetch_github_stars,
  flag_minimize_output,
  argv1_is_http,
  found_file_content,
  number_of_threads = cli_process(argv1, argv_flags, log)

  log.verbose "Number of threads: #{number_of_threads}"
  m = "Option white list: #{option_white_list}"
  log.verbose m unless option_white_list.nil?

  if flag_fetch_github_stars || option_pull_request
    creds = github_netrc
    if creds.nil?
      error.log 'Missing GitHub credentials in .netrc'
      exit(1)
    end
  end

  # start
  elapsed_time_start = Time.now

  log.file_write "$ #{PRODUCT} #{ARGV.join ' '} \n\n"

  u, r = if argv1_is_http || found_file_content
           argv1
         else
           log.verbose 'Attempt to get default branch (unauthenticated)'
           message, parsed = github_repo_unauthenticated(argv1, log)
           log.verbose "Parsed message: #{message}"

           if message == 'Not Found' || message == 'Moved Permanently'
             m = "Retrieving repo #{argv1} "
             log.error "#{m.red} #{message.downcase}"
             exit(1)
           elsif message.include? 'API rate limit exceeded'
             log.error "GitHub #{message}"
             log.add 'Finding readme...'

             default_branch = 'master'
             net_find_github_url_readme(argv1, default_branch)
           else
             default_branch = parsed['default_branch']
             log.add github_repo_json_info(parsed,
                                           default_branch,
                                           argv1)
             net_find_github_url_readme(argv1, default_branch)
           end # if message ..
         end # if argv1_is_http ..
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
  File.open(file_copy, 'w') { |f| f.write(content) }
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

        output_status(flag_minimize_output, res.status, link, log)

        next if res.status == 200

        m = "#{status_glyph res.status, link, log} #{res.status} #{link}"
        issues.push(m)

        if res.status >= 500
          misc.push(link)
        elsif res.status >= 400
          failures.push(link)
        elsif res.status >= 300
          redirect = resolve_redirects(link, log)
          log.verbose "#{link} was redirected to \n#{redirect}".yellow
          if redirect.nil?
            log.add "#{em_mad} No redirect found for #{link}"
          else
            redirects[link] = redirect unless
              in_white_list(link, option_white_list, log)
          end
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
        m = "\n#{misc.count} misc. "\
            "#{pluralize 'item', misc.count}: #{misc}"
        log.add m.white
      end
    end # unless option_github_stars_only

    if flag_fetch_github_stars
      github_repos = links_to_check.select { |link|
        link.to_s.downcase.include? 'github.com' and link.count('/') == 4
      }.map { |url| url.split('.com/')[1] }.reject { |x| x.include? '.' }.uniq
      log.verbose github_repos

      if github_repos.count == 0
        log.add 'No GitHub repos found'.white
      else
        m = "\n🔎  Getting information for #{github_repos.count} GitHub ".white
        log.my_print m
        log.add pluralize('repo', github_repos.count).white

        github_repos_info(github_repos, number_of_threads, github_client, log)
      end # if github_repos.count == 0
    end # flag_fetch_github_stars
  end # if links_to_check.count==0

  redirects = [] if redirects.nil?

  if redirects.count > 0
    File.open(file_redirects, 'w') { |f| f.write(redirects) }

    m = "\n#{em_status_yellow} #{redirects.count} "\
        "#{pluralize 'redirect', redirects.count}"
    log.add m.yellow

    log.verbose "Replacing redirects in temp file #{file_updated}.."
    File.open(file_copy, 'a+') do |f|
      original = f.read
      replaced = original

      redirects.each do |key, array|
        log.add "#{key.yellow} redirects to \n#{array} \n\n"
        replaced = replaced.gsub key, array
      end # redirects.each

      File.open(file_updated, 'w') do |ff|
        puts "Wrote redirects replaced to #{file_updated.white}"
        ff.write(replaced)
      end
    end # File.open(FILE_TEMP, 'a+') { |f|
  end # redirects.count

  puts "Wrote log to #{file_log.white}"

  if option_pull_request
    m = 'Would you like to open a pull request to update the redirects? (y/n) '
    print m
    user_input = STDIN.gets.chomp

    if user_input.downcase == 'y'
      log.add "\nCreating pull request on GitHub for #{argv1} ...".white
      p = github_pull_request(argv1, default_branch, readme, file_updated, log)
      log.add "Pull request created: #{p}".white
    end # user input
  end # option pull request

  elapsed_seconds = Time.now - elapsed_time_start
  log.verbose "Elapsed time in seconds: #{elapsed_seconds}"

  m = "\n🕐  Time elapsed: ".white << elapsed(elapsed_seconds)
  log.add m

  log.add ''
  failures = [] if failures.nil?
  if failures.count == 0
    log.add "#{em_logo} No failures for #{argv1.blue}".white
  else
    if (failures.count == 1) && (failures.include? CONTROLLED_ERROR)
      log.add "The only failure was the controlled failure #{em_sunglasses}"
    else
      m = "#{em_status_red} #{failures.count} "\
          "#{pluralize 'failure', failures.count} for #{argv1.blue}"
      log.add m.red
      # exit(1)
    end
  end

  log.file_write "\nCreated with #{PROJECT_URL} \n"

  # TODO: check for twitter creds

  unless ARGV.include? 'travis'
    option_happy = '-h'
    option_gist = 'gist'
    option_tweet = 'tweet'
    m = "\nShare results? (#{option_gist.white} | "\
        "#{option_tweet.white} [#{option_happy.white}] [message] | n) "
    print m
    user_input = STDIN.gets.chomp

    if user_input.downcase == option_gist or user_input.include? option_tweet
      gist_url, = Frankenstein.github_create_gist file_log, true

      if user_input.include? option_tweet
        client = twitter_client
        message = user_input.gsub(option_tweet, '').tr(option_happy, '').strip
        tweet = Frankenstein.twitter_frankenstein_tweet(argv1, gist_url,
                                                        message)
        option_happy = user_input.include? option_happy
        tweet << Frankenstein.twitter_random_happy_emoji if option_happy
        t = client.update tweet
        twitter_log Frankenstein.twitter_tweet_url(client, t)
      end # if user_input.downcase == 't'
    end # user input == y
  end

  exit(1) if (failures.count > 0) && !(failures.include? CONTROLLED_ERROR)
end # module
