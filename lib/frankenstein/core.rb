# Frankenstein core
module Frankenstein
  require 'parallel'
  require 'colored'
  require 'json'

  require 'frankenstein/constants'
  require 'frankenstein/diff'
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
      proj = clean_pull_url.gsub(/\/pull.*$/, '').sub('https://github.com/', '')
      puts proj
      username = proj.gsub(/\/.*$/, '')
      puts username
      fork = proj.sub(username, github_netrc_username)
      puts fork

      puts "\n#{em_logo} Creating GitHub client"
      client = github_client

      puts "\n#{em_logo} Getting changes ... "
      f = client.pull_files proj, number
      changes = f[0][:additions]
      m = 'Found '\
          "#{pluralize2 changes, 'change'} "
      puts m

      puts "\n#{em_logo} Checking merge status for #{proj.white} ..."
      merged = client.pull_merged? proj, number
      puts 'Pull request was merged 🎉'.green if merged == true

      puts "\n#{em_logo} Checking pull request status ..." unless merged == true
      state = client.pull(proj, number)[:state]
      puts 'Pull request was closed 😡' if state == 'closed' && merged == false

      check_comments(client, proj, number, em_logo)

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

        puts "   #{redirects.uniq.count} unique" if
          redirects.uniq.count != redirects.count

        redirects.uniq.each do |hash|
          original, redirect = hash.first
          log.add "#{original.yellow} redirects to \n#{redirect.yellow} "

          changes = Differ.diff_by_word(redirect, original).changes
          changes.each do |c|
            if c.delete == ''
              m = "#{c.insert.green} was added"
            elsif c.insert == ''
              m = "#{c.delete.red} was removed"
            else
              m = "#{c.delete.red} was replaced by #{c.insert.green}"
            end
            log.add "  #{m}"

            puts '  ' << '!!!'.red_on_yellow if
              (c.insert != 'https') && (original.include? '//github.com/')
          end

          log.add ''

          replaced = replaced.sub original, redirect
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
          log.add m
        end

        misc = []
        issues = []
        failures = []
        redirects = []
        unless option_github_stars_only
          Parallel.each(links_to_check, in_threads: number_of_threads) do |link|
            if in_white_list link, option_white_list, log
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

            if res.status >= 500
              misc.push(link)
            elsif res.status >= 400
              failures.push(link)
            elsif res.status >= 300
              redirect = net_resolve_redirects(link, log)
              log.verbose "#{link} was redirected to \n#{redirect}".yellow

              if redirect.nil?
                log.add "#{em_mad} No redirect found for #{link}"
              elsif redirect == link
                log.add "😓  Redirect is the same for #{link}"
              else
                if in_white_list2 REDIRECTED_WHITE_LIST, redirect, false, log
                  log.add "#{em_status_white} #{link.white} is in the "\
                    'redirect white list'
                  next
                end

                issues.push "#{status_glyph res.status, link, log} "\
                  "#{res.status} #{link}"
                redirects.push link => redirect
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

      core_process_redirects(
        file_redirects,
        file_copy,
        file_updated,
        redirects,
        log) if redirects.count > 0

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
        if failures.count > 0
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

    def core_scan_time_ago(t, index, argv1)
      today = Time.now.to_i
      seconds = today - t

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

      m
    end

    def core_scan(argv_1, force = false)
      c = File.read argv_1
      links, * = core_find_links c
      r = github_get_repos links
      puts "Scanning #{pluralize2(r.count, 'repo').white}"

      flag_verbose = false
      number_of_threads = 10
      logs = core_logs
      records = io_json_read FILE_VISITS
      r.each.with_index do |argv1, index|
        unless force
          if logs.include? argv1.sub('/', '-')
            match = argv1.sub('/', '-')
            t = core_logs.match(/(.){22}(#{match})/)
            epoch = t[0].gsub(/-.*/, '').to_i

            puts core_scan_time_ago epoch, index, argv1
            next
          elsif records.keys.include? argv1
            d = records[argv1]['log'].last['date']
            t = (Time.parse d).to_i

            puts core_scan_time_ago t, index, argv1
            next
          end
        end

        elapsed_time_start = Time.now

        log = Log.new(flag_verbose, argv1)

        file_copy = log.filename(FILE_COPY)
        file_updated = log.filename(FILE_UPDATED)
        file_redirects = log.filename(FILE_REDIRECTS)
        file_log = log.filelog

        if github_creds
          c = github_client
          repo = argv1

          b = github_default_branch c, repo
          readme, content = github_readme c, repo

          if readme.nil?
            print 'Error '.red
            puts content
            io_record_visits(argv1,
                             0,
                             [],
                             log.identifier,
                             nil)
            next
          end

          m, raw_info = github_repo_info_client c, repo, b
          log.add m
        else
          message, parsed = github_repo_unauthenticated(argv1, log)

          if github_repo_error message
            log.error github_repo_error_message message, argv1
            next
          elsif message.include? 'API rate limit exceeded'
            log.error "GitHub #{message}"
            log.add 'Finding readme...'

            b = 'master'
            the_url, readme = net_find_github_url_readme(argv1, b)
          else
            b = parsed['default_branch']
            m, raw_info = github_repo_json_info(parsed, b, argv1)
            log.add m

            the_url,
            readme,
            content = github_readme_unauthenticated(argv1, log)

            if the_url.nil?
              puts "No content found for #{argv1.white}"
              next
            end
          end # if message ..
        end

        content = net_get(the_url).body if content.nil?
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
          false, # flag_minimize_output,
          false, # flag_fetch_github_stars,
          file_redirects,
          file_updated,
          file_copy,
          file_log)

        redirects = r[1]
        io_record_visits(argv1,
                         links_to_check.count,
                         redirects,
                         log.identifier,
                         raw_info)
      end # r.each
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
