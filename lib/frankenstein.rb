require "frankenstein/version"
require "frankenstein/constants"
require "frankenstein/logging"
require "frankenstein/usage"

# Check for live URLs on a page
module Frankenstein
  require 'faraday'
  require 'faraday_middleware'
  require 'json'
  require 'parallel'
  require 'colored'
  require 'octokit'
  require 'netrc'

  # process cli arguments
  argv1, argv_flags = ARGV

  option_github_stars_only = ARGV.include? OPTION_STARS
  $option_log_to_file = ARGV.include? OPTION_LOG
  flag_control_failure = argv_flags.to_s.include? FLAG_FAIL
  $flag_verbose = argv_flags.to_s.include? FLAG_VERBOSE

  if argv1
    argv1_is_http = argv1.match(/^http/)

    if !argv1_is_http
      begin
        found_file_content = File.read(argv1)
      rescue Exception => e
        verbose "Not a file #{e}"
      end

      option_pull_request = if argv1.include? "/"
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
    regex = "#{OPTION_ROW}#{SEPARATOR}"
    verbose "Regular expression: #{regex}"
    temp = ARGV.find { |e| /#{regex}/ =~ e }
    log_number_of_items_per_row = if temp
      temp.split(SEPARATOR)[1].to_i
    else
      10 # default is 10 items per output rows
    end
  end

  regex = "#{OPTION_THREADS}#{SEPARATOR}"
  verbose "Regular expression: #{regex}"
  temp = ARGV.find { |e| /#{regex}/ =~ e }
  $number_of_threads = if temp
    temp.split(SEPARATOR)[1].to_i
  else
    5 # default is 5 threads
  end
  verbose "Number of threads: #{$number_of_threads}"

  if flag_fetch_github_stars || option_pull_request
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
     return code
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
          b.use FaradayMiddleware::FollowRedirects;
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
    verbose "Number of minimized output items per row: #{log_number_of_items_per_row}"
  end

  the_url = if argv1_is_http || found_file_content
    argv1
  else
    argv1_is_github_repo = argv1

    # note github api has a rate limit of 60 unauthenticated requests per hour https://developer.github.com/v3/#rate-limiting
    json_url = GITHUB_API_BASE + "repos/" + argv1_is_github_repo
    f_puts "Finding default branch for #{argv1_is_github_repo.white}"
    verbose json_url

    body = Faraday.get(json_url).body
    verbose body
    parsed = JSON.parse(body)

    message = parsed['message']
    verbose "Parsed message: #{message}"

    if message.nil?
      message = ''
    end

    if message.include? "API rate limit exceeded"
      f_puts "#{mad} Error: GitHub #{message}".red

      f_puts "Finding readme..."
      base = "https://raw.githubusercontent.com/#{argv1}/master/"
          "#{base}#{
            README_VARIATIONS.find { |x|
              temp = "#{base}#{x}"
              $readme = x
              verbose "Readme found: #{$readme}"
              status(temp) < 400 }
              }"
    else
      if message == "Not Found"
        f_puts "#{mad} Error retrieving repo #{argv1_is_github_repo}".red
        exit 1
      end

      default_branch = parsed['default_branch']
      repo_description = parsed['description']
      repo_stars = parsed['stargazers_count']

      f_puts "Found: #{default_branch.white} for #{argv1_is_github_repo} — #{repo_description} — #{repo_stars}⭐️ "

      base = "https://raw.githubusercontent.com/#{argv1}/#{default_branch}/"
      the_url = "#{base}#{
          README_VARIATIONS.find { |x|
          temp = "#{base}#{x}"
          $readme = x
          verbose "Readme found: #{$readme}"
          status(temp) < 400 }
          }"
    end # if message ==
  end # if message.include? "API..

  f_print "#{logo} Processing links for ".white
  f_print the_url.blue
  f_puts " ...".white

  links_found = if found_file_content
    URI.extract(found_file_content, /http()s?/)
  else
    code = status the_url

    if code != 200
      error_message = (argv1_is_http) ? "url response" : "could not find readme in master branch"
      f_puts "#{mad} Error, #{error_message.red} (status code: #{code.to_s.red})"
      exit
    end

    res = Faraday.get(the_url)
    content = res.body
    File.open(FILE_TEMP, 'w') { |f|
      f.write(content)
    }
    URI.extract(content, /http()s?/)
  end
  verbose "Links found: #{links_found}"

  links_to_check = links_found.reject { |x|
    x.length < 9
  }.map { |x|
    x.gsub(/\).*/,'').gsub(/'.*/,'').gsub(/,.*/,'')
    # ) for markdown
    # ' found on https://fastlane.tools/
    # , for link followed by comma
  }.uniq

  if flag_control_failure
    links_to_check.unshift(CONTROLLED_ERROR)
  end

  verbose "🔎  Links found: ".white
  verbose links_to_check

  if links_to_check.count==0
    error_result_header 'no links found'
  else
    if !option_github_stars_only
      f_print "🔎  Checking #{links_to_check.count} ".white
      f_puts pluralize("link", links_to_check.count).white
      if flag_control_failure
        f_puts "   (including a controlled failure)"
      end
    end

    misc = []
    issues = []
    failures = []
    redirects = Hash.new
    if !option_github_stars_only
      Parallel.each_with_index(links_to_check, :in_threads => $number_of_threads) do |link, index|
        begin
        res = Faraday.get(link)
        rescue Exception => e
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
          if ((index + 1) % log_number_of_items_per_row == 0) and $number_of_threads == 0
            f_puts " #{log_number_of_items_per_row * (1 +(index / log_number_of_items_per_row)) }"
          end
        else
          f_puts_with_index index+1, links_to_check.count, "#{status_glyph res.status, link} #{res.status==200 ? "" : res.status} #{link}"
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
          end
        end
      end # Parallel

      if issues.count>0
        percent = issues.count * 100 / links_to_check.count
        error_result_header "#{issues.count} #{pluralize "issue", issues.count} (#{percent.round}%)"
        f_puts "   (#{issues.count} of #{links_to_check.count} #{pluralize "link", links_to_check.count})"
        f_puts issues
      else
        f_puts "#{"\nfrankenstein".white} #{"found no errors".green} #{sunglasses}"
      end

      if misc.count>0
        f_puts "\n#{misc.count} misc. #{pluralize "item", misc.count}: #{misc}".white
      end
    end #if !option_github_stars_only

    if flag_fetch_github_stars
      github_repos = links_to_check.select { |link|
        link.to_s.downcase.include? "github.com" and link.count('/')==4
      }.map { |url|
        url.split('.com/')[1]
      }.reject { |x|
        x.include? "."
      }.uniq
      verbose github_repos

      if github_repos.count == 0
        f_puts "No GitHub repos found".white
      else
        f_print "\n🔎  Getting star count for #{github_repos.count} GitHub ".white
        f_puts pluralize("repo",github_repos.count).white

        client = Octokit::Client.new(:netrc => true)
        Parallel.each_with_index(github_repos, :in_threads => $number_of_threads) do |repo, index|
        # github_repos.each_with_index { |repo, index|
          verbose "Attempting to get stars for #{repo}"

          begin
          gh_repo = client.repo(repo)
          rescue Exception => e
            f_print "#{mad} Error getting repo for "
            f_print repo.white
            f_puts ": #{e.message.red}"
            next
          end

          count = gh_repo.stargazers_count
          f_puts_with_index index+1, github_repos.count, "⭐️  #{count} #{repo} #{heat_index count}"
        end # Parallel
      end # if github_repos.count == 0
    end # flag_fetch_github_stars
  end # if links_to_check.count==0

  if redirects.nil?
    redirects = []
  end

  if redirects.count > 0
    f_puts "\n#{status_yellow} #{redirects.count} #{pluralize "redirect", redirects.count}".yellow

    verbose "Replacing redirects in temp file #{FILE_TEMP}.."
    File.open(FILE_TEMP, 'a+') { |f|
      original = f.read
      replaced = original

      redirects.each do |key, array|
        f_puts "#{key.yellow} redirects to \n#{array} \n\n"
        replaced = replaced.gsub key, array
      end #redirects.each

      File.open(FILE_TEMP, 'w') { |f|
        f_puts "Wrote redirects replaced to #{FILE_TEMP.white}"
        f.write(replaced)
      }
    } # File.open(FILE_TEMP, 'a+') { |f|
  end # redirects.count

  if $option_log_to_file
    f_puts "Wrote log to #{FILE_LOG.white}"
  end 

  if option_pull_request
    print "Would you like to open a pull request? (y/n) "
    user_input = STDIN.gets.chomp

    if user_input.downcase == 'y'
      f_puts "\nCreating pull request on GitHub for #{argv1} ...".white

      github = Octokit::Client.new(:netrc => true)

      repo = argv1
      forker = Netrc.read[NETRC_GITHUB_MACHINE][0]
      fork = repo.gsub(/.*\//,"#{forker}/")
      verbose "Fork: #{fork}"

      github.fork(repo)

      sleep 2 # give it time to create repo 😢

      branch = "master"

      ref = "heads/#{branch}"

      # commit to github via http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/
      sha_latest_commit = github.ref(fork, ref).object.sha
      sha_base_tree = github.commit(fork, sha_latest_commit).commit.tree.sha
      file_name = $readme
      my_content = File.read(FILE_TEMP)

      blob_sha = github.create_blob(fork, Base64.encode64(my_content), "base64")
      sha_new_tree = github.create_tree(fork,
                                         [ { :path => file_name,
                                             :mode => "100644",
                                             :type => "blob",
                                             :sha => blob_sha } ],
                                         {:base_tree => sha_base_tree }).sha
      commit_message = PULL_REQUEST_TITLE
      sha_new_commit = github.create_commit(fork, commit_message, sha_new_tree, sha_latest_commit).sha
      updated_ref = github.update_ref(fork, ref, sha_new_commit)

      verbose "Sent commit to fork #{fork}"

      head = "#{forker}:#{branch}"
      verbose "Set head to #{head}"

      created = github.create_pull_request(repo, branch, head, "Update redirects", PULL_REQUEST_DESCRIPTION)
      pull_link = created[:html_url].blue
      f_puts "Pull request created: #{pull_link}".white

      github.delete_repository(fork)
      verbose "Deleted fork"

    end # user input
  end

  elapsed_seconds = Time.now - elapsed_time_start
  verbose "Elapsed time in seconds: #{elapsed_seconds}"
  f_print "\n🕐  Time elapsed: ".white
  case
  when elapsed_seconds>60
    minutes = (elapsed_seconds/60).floor
    seconds = elapsed_seconds - minutes * 60
    f_puts "#{minutes.round(0)} #{pluralize "minute", minutes} #{seconds>0 ? seconds.round(0).to_s << "s" : ""}"
  else
    f_puts "#{elapsed_seconds.round(2)} #{pluralize "second", elapsed_seconds}"
  end

  if $option_log_to_file
    franken_log "End: #{Time.new}"
  end

  if failures.nil?
    failures = []
  end

  f_puts ""
  if failures.count == 0
    f_puts "#{logo} No failures for #{argv1.blue}".white
  else
    if (failures.count == 1) && (failures.include? CONTROLLED_ERROR)
      f_puts "The only failure was the controlled failure #{sunglasses}"
    else
      f_puts "#{status_red} #{failures.count} #{pluralize "failure", failures.count} for #{argv1.blue}".red
      exit(1)
    end
  end
end # module
