# Frankenstein core
module Frankenstein
  require 'parallel'
  require 'colored'
  require 'json'

  require 'frankenstein/constants'
  require 'frankenstein/github'
  require 'frankenstein/io'
  require 'frankenstein/log'
  require 'frankenstein/network'
  require 'frankenstein/output'
  require 'frankenstein/twitter'

  class << self
    def core_find_links(content)
      links_found = URI.extract(content, /http()s?/)

      links_to_check =
        links_found.reject { |x| x.length < 9 }
        .map { |x| x.gsub(/\).*/, '').gsub(/'.*/, '').gsub(/,.*/, '').gsub('/:', '/') }
      # ) for markdown
      # ' found on https://fastlane.tools/
      # , for link followed by comma
      # : found on ircanywhere/ircanywhere

      [links_to_check, links_found]
    end

    def core_links_to_check(_, json_url)
      c = net_get json_url
      json = JSON.parse c.body

      title = json['title']
      body = json['body']
      content = "#{title} #{body}"

      links_to_check, * = core_find_links content

      match = content.match /.*\/.*/
      matched = match.to_s.split ' '
      matched = matched.select { |x| x.include? '/' }

      links_to_check = links_to_check + matched if matched.count > 0

      [links_to_check.uniq, json]
    end

    def core_logs
      d = Dir.entries(FILE_LOG_DIRECTORY)
      d.join ' '
    end

    def check_comments(client, project, number, logo)
      puts "\n#{logo} Checking comments ..."
      comments = client.issue_comments project, number
      puts 'No comments' if comments.count == 0

      comments.each do |c|
        u = '@' << c[:user][:login]
        m = "\n#{u.white}: #{c[:body]} "
        puts m
      end unless comments == 0
      # end
    end

    def delete_fork(client, fork, logo)
      puts "\n#{logo} Deleting fork #{fork} ..."
      client.delete_repository fork
    end

    def finish(tweet, clean_pull_url)
      puts tweet

      client = twitter_client
      t = client.update tweet

      puts "\nTweet sent #{twitter_tweet_url(client, t).blue}"

      core_open_safari clean_pull_url
    end

    def core_open_safari(url, verbose = true)
      puts "\nOpening Safari ..." if verbose
      system("open -a Safari #{url}")
    end

    def core_merge(argv1)
      puts "#{em_logo} Parsing input #{argv1.white} ..."
      clean_pull_url = argv1.gsub(/#.*$/, '')
      puts clean_pull_url
      number = clean_pull_url.gsub(/.*pull\//, '')
      puts number
      project = clean_pull_url.gsub(/\/pull.*$/, '').sub('https://github.com/', '')
      puts project
      username = project.gsub(/\/.*$/, '')
      puts username
      fork = project.sub(username, github_netrc_username)
      puts fork

      puts "\n#{em_logo} Creating GitHub client"
      client = github_client

      puts "\n#{em_logo} Getting changes ... "
      f = client.pull_files project, number
      changes = f[0][:additions]
      m = 'Found '\
          "#{pluralize2 changes, 'change'} "
      puts m

      puts "\n#{em_logo} Checking merge status for #{project.white} ..."
      merged = client.pull_merged? project, number
      puts 'Pull request was merged 🎉' if merged == true

      puts "\n#{em_logo} Checking pull request status ..." unless merged == true
      state = client.pull(project, number)[:state]
      puts 'Pull request was closed 😡' if state == 'closed' && merged == false

      check_comments(client, project, number, em_logo)

      puts ''
      if merged == true || state == 'closed'
        result = delete_fork(client, fork, em_logo)
        if result == false
          puts "The fork #{fork.red} has already been deleted.."
          core_open_safari clean_pull_url
          exit
        end

        puts "\n#{em_logo} Crafting tweet ... \n\n"
        if (merged == true)
          t = "#{em_logo}#{clean_pull_url} was merged with "\
              "#{pluralize2 changes, 'change'} "\
              "#{twitter_random_happy_emoji}"
        else # closed :-(
          t = "#{em_logo}This pull request with "\
              "#{pluralize2 changes, 'change'} "\
              "looked pretty good ¯/_(ツ)_/¯ #{clean_pull_url}/files"
        end

        finish t, clean_pull_url
      else
        puts 'Pull request is still open 📗'
      end
    end

    def core_process_redirects(
      file_redirects,
      file_copy,
      file_updated,
      redirects,
      log)
      io_json_write file_redirects, redirects

      m = "\n#{em_status_yellow} #{pluralize2 redirects.count, 'redirect'}"
      log.add m.yellow

      log.verbose "Replacing redirects in temp file #{file_updated}.."
      File.open(file_copy, 'a+') do |f|
        original = f.read
        replaced = original

        redirects.each do |hash|
          key, array = hash.first
          diff = array.length - key.length

          colored_diff = diff
          colored_diff = colored_diff.to_s.red if diff.abs > 1
          log.add "#{key.yellow} #{colored_diff} redirects to \n#{array} \n\n"
          replaced = replaced.sub key, array
        end # redirects.each

        File.open(file_updated, 'w') do |ff|
          puts "Wrote redirects replaced to #{file_updated.white}"
          ff.write(replaced)
        end
      end # File.open(FILE_TEMP, 'a+') { |f|
    end

    def core_run(
      elapsed_time_start,
      log,
      links_to_check,
      argv1,
      number_of_threads,
      branch,
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
      log.verbose '🔎  Links found: '.white
      log.verbose links_to_check

      if links_to_check.count == 0
        log.error_header 'no links found'
      else
        unless option_github_stars_only
          m = "🔎  Checking #{pluralize2 links_to_check.count, 'link'}"
          m << ' (including a controlled failure)' if flag_control_failure
          log.add m
        end

        misc = []
        issues = []
        failures = []
        redirects = []
        unless option_github_stars_only
          Parallel.each(links_to_check, in_threads: number_of_threads) do |link|
            if in_white_list(link, option_white_list, log)
              output_status(flag_minimize_output, WHITE_LIST_STATUS, link, log)
              next
            end

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
                redirects.push({ link => redirect })
              end
            end # if res.status != 200
          end # Parallel

          output_issues(issues, links_to_check, log)
          output_misc(misc, log) if misc.count > 0
        end # unless option_github_stars_only

        if flag_fetch_github_stars
          github_repos = github_get_repos links_to_check
          log.verbose github_repos

          if github_repos.count == 0
            log.add 'No GitHub repos found'.white
          else
            m = "\n🔎  Getting information for "\
                "#{pluralize2 github_repos.count, 'GitHub repo'}".white
            log.add m

            github_repos_info(github_repos, number_of_threads, github_client,
                              log)
          end # if github_repos.count == 0
        end # flag_fetch_github_stars
      end # if links_to_check.count==0

      redirects = [] if redirects.nil?

      if redirects.count > 0
        core_process_redirects(
          file_redirects,
          file_copy,
          file_updated,
          redirects,
          log)
      end # redirects.count

      puts "Wrote log to #{file_log.white}"

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
          m = "#{em_status_red} #{pluralize2 failures.count, 'failure'} "\
              "for #{argv1.blue}".red
          log.add m
        end
      end

      log.file_write "\nCreated with #{PROJECT_URL} "\
                     "#{Time.now.strftime('%b %d, %Y')} \n"

      f = "#{FILE_LOG_DIRECTORY}/#{log.identifier}-stats"
      f << "-r#{redirects.count}" if redirects.count > 0
      f << "-f#{failures.count}" if failures.count > 0
      File.open(f, 'w') { |ff| ff.write("#{PRODUCT} info for #{argv1}") }

      f = "#{FILE_LOG_DIRECTORY}/#{log.identifier}-info"
      hash = {
        repo: argv1,
        branch: branch,
        readme: readme
      }
      io_json_write f, hash

      [failures, redirects]
    end

    def core_scan(argv_1)
      c = File.read argv_1
      links, * = Frankenstein.core_find_links c
      r = Frankenstein.github_get_repos links
      # puts r
      puts "Scanning #{Frankenstein.pluralize2(r.count, 'repo').white}"

      flag_verbose = false
      number_of_threads = 10
      logs = Frankenstein.core_logs
      r.each.with_index do |argv1, index|
        if logs.include? argv1.sub('/', '-')
          match = argv1.sub('/', '-')
          t = core_logs.match(/(.){22}(#{match})/)
          epoch = t[0].gsub(/-.*/, '').to_i
          today = Time.now.to_i
          seconds = today - epoch
          minutes = seconds / 60
          hour = minutes / 60
          minutes -= (60 * hour) if hour > 0
          day = hour / 24

          m = "#{index + 1} Skipping #{argv1.white}, run "
          if day > 0
            m << "#{pluralize2 day, 'day'}"
          else
            if hour > 0
              m << "#{hour}h #{minutes}m"
            else
              m << "#{pluralize2 minutes, 'minute'}"
            end
          end
          m << ' ago'

          puts m
          next
        end

        elapsed_time_start = Time.now

        log = Frankenstein::Log.new(flag_verbose, argv1)

        file_copy = log.filename(Frankenstein::FILE_COPY)
        file_updated = log.filename(Frankenstein::FILE_UPDATED)
        file_redirects = log.filename(Frankenstein::FILE_REDIRECTS)
        file_log = log.filelog

        message, parsed = Frankenstein.github_repo_unauthenticated(argv1, log)
        if message == 'Not Found' || message == 'Moved Permanently'
          m = "Retrieving repo #{argv1} "
          log.error "#{m.red} #{message.downcase}"
          next
        elsif message.include? 'API rate limit exceeded'
          log.error "GitHub #{message}"
          log.add 'Finding readme...'

          b = 'master'
          the_url, readme = Frankenstein.net_find_github_url_readme(argv1, b)
        else
          b = parsed['default_branch']
          m, raw_info =
            Frankenstein.github_repo_json_info(parsed, b, argv1)
          log.add m
          the_url, readme = Frankenstein.net_find_github_url_readme(argv1, b)
        end # if message ..

        content = net_get(the_url).body
        File.open(file_copy, 'w') { |f| f.write(content) }

        links_to_check, * = core_find_links content

        r = core_run(
          elapsed_time_start,
          log,
          links_to_check,
          argv1,
          number_of_threads,
          b,
          readme,
          false, # option_github_stars_only,
          true,  # option_head,
          false, # option_white_list,
          false, # flag_control_failure,
          false, # flag_minimize_output,
          false, # flag_fetch_github_stars,
          file_redirects,
          file_updated,
          file_copy,
          file_log)

        redirects = r[1]
        io_record_visits(argv1, redirects, log.identifier, raw_info)
      end # Parallel
    end

    def core_todo_add(item)
      f = FILE_TODO
      log = if File.exist? f
              io_json_read f
            else
              []
            end

      log.push item
      log = log.uniq

      io_json_write f, log

      log
    end
  end # class
end
