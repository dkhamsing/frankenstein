require 'frankenstein/cli'
require 'frankenstein/core'
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
  cli_create_log_dir

  # process cli arguments
  argv1, argv_flags = ARGV

  if argv1.nil?
    usage
    exit
  end

  argv1 = cli_filter_github(argv1)
  filtered = argv1.sub('/', '-') # TODO: filtered should be in core
  if core_logs.scan(filtered).count > 0
    m = "#{em_logo} there are previous runs for #{argv1.white} in "\
        "#{FILE_LOG_DIRECTORY.green}"
    puts m
    pattern = "#{FILE_LOG_DIRECTORY}/*#{filtered}.frankenstein"
    r = Dir.glob pattern
    puts pluralize2 r.count, 'file'
    puts r
  end

  flag_verbose = cli_log(argv_flags)
  log = Frankenstein::Log.new(flag_verbose, argv1)

  file_copy = log.filename(FILE_COPY)
  file_updated = log.filename(FILE_UPDATED)
  file_redirects = log.filename(FILE_REDIRECTS)
  file_log = log.filelog

  option_github_stars_only,
  option_head,
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

  if flag_fetch_github_stars && !github_creds
    log.error GITHUB_CREDS_ERROR
    exit(1)
  end

  # start
  elapsed_time_start = Time.now

  log.file_write "$ #{PRODUCT} #{ARGV.join ' '} \n\n"

  the_url,
  readme,
  content =
    if argv1_is_http || found_file_content
      argv1
    else
      log.verbose 'Attempt to get default branch (unauthenticated)'
      message, parsed = github_repo_unauthenticated(argv1, log)
      log.verbose "Parsed message: #{message}"

      if github_repo_error message
        log.error github_repo_error_message message, argv1
        exit(1)
      elsif message.include? 'API rate limit exceeded'
        log.error "GitHub #{message}"
        log.add 'Finding readme...'

        default_branch = 'master'
        net_find_github_url_readme(argv1, default_branch)
      else
        default_branch = parsed['default_branch']
        m, raw_info = github_repo_json_info(parsed, default_branch, argv1)
        log.add m
        github_readme_unauthenticated(argv1, log)
      end # if message ..
    end # if argv1_is_http ..

  if the_url.nil?
    puts "No content found for #{argv1.white}"
    exit
  end

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

              content = net_get(the_url).body if content.nil?
              content
            end
  File.open(file_copy, 'w') { |f| f.write(content) }

  links_to_check, links_found = core_find_links content
  log.verbose "Links found: #{links_found}"
  links_to_check.unshift(CONTROLLED_ERROR) if flag_control_failure

  failures, redirects =
    core_run(
      elapsed_time_start,
      log,
      links_to_check,
      argv1,
      number_of_threads,
      default_branch,
      readme,
      option_github_stars_only,
      option_head,
      option_white_list,
      flag_control_failure,
      flag_minimize_output,
      flag_fetch_github_stars,
      file_redirects,
      file_updated,
      file_copy,
      file_log)

  # TODO: check for twitter creds

  if github_creds && !(ARGV.include? OPTION_SKIP)
    io_record_review argv1

    option_happy = '-h'
    option_gist = 'g'
    option_tweet = 't'
    option_pull = 'p'
    option_w = 'w'

    done = nil
    while done.nil?
      m = "\nNext? (#{option_pull.white}ull request | "\
          "white list #{option_w.white}=<s1^s2..> | #{option_gist.white}ist | "\
          "#{option_tweet.white}weet [#{option_happy.white}] [message] | "\
          'enter to end) '
      print m
      user_input = STDIN.gets.chomp

      if user_input.include? option_w
        wl = user_input.sub("#{option_w}=", '')
        list = wl.split '^'

        list.each do |x| # TODO: this looks like it could be improved
          redirects.reject! do |hash|
            key, * = hash.first
            key.include? x
          end
        end

        core_process_redirects(
          file_redirects,
          file_copy,
          file_updated,
          redirects,
          log)
        next
      end

      if user_input.downcase == option_pull
        unless github_repo_exist(github_client, argv1)
          log.error "#{argv1.red} is not a repo"
          exit(1)
        end

        log.add "\nCreating pull request on GitHub for #{argv1} ...".white
        desc = github_pull_description(redirects, failures)
        p = github_pull_request(argv1, default_branch, readme, file_updated,
                                desc, log)
        log.add "Pull request created: #{p.blue}".white
        io_record_pull(argv1, p)
        done = true
      elsif (user_input.downcase == option_gist) ||
            (user_input.include? option_tweet)
        done = true
        gist_url, * = Frankenstein.github_create_gist file_log, true

        if user_input.include? option_tweet
          client = twitter_client
          message = user_input.sub(option_tweet, '').sub(option_happy, '').strip

          happy = user_input.include? option_happy
          tweet = Frankenstein.twitter_frankenstein_tweet(argv1, gist_url,
                                                          message, happy)
          t = client.update tweet
          twitter_log Frankenstein.twitter_tweet_url(client, t)
        end # if user_input.downcase == 't'
      else  # any other key
        done = true
      end # user input == y
    end # while
  end # if github_creds

  io_record_visits(
    argv1,
    redirects,
    log.identifier,
    raw_info) unless found_file_content

  exit(1) if (failures.count > 0) && !(failures.include? CONTROLLED_ERROR)
end # module
