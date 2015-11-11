# Frankenstein core
module Frankenstein
  require 'parallel'
  require 'colored'

  require 'frankenstein/constants'
  require 'frankenstein/io'
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

    def core_logs
      d = Dir.entries(Frankenstein::FILE_LOG_DIRECTORY)
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

    def finish(tweet, project, clean_pull_url)
      puts tweet

      client = Frankenstein.twitter_client
      t = client.update tweet

      puts "\nTweet sent #{Frankenstein.twitter_tweet_url(client, t).blue}"

      puts "\n#{PRODUCT} finished for #{project.white}"

      system("open -a Safari #{clean_pull_url}")
    end

    def core_merge(argv1)
      logo = Frankenstein.em_logo
      puts "#{logo} Parsing input #{argv1.white} ..."
      clean_pull_url = argv1.gsub(/#.*$/, '')
      puts clean_pull_url
      number = clean_pull_url.gsub(/.*pull\//, '')
      puts number
      project = clean_pull_url.gsub(/\/pull.*$/, '').sub('https://github.com/', '')
      puts project
      username = project.gsub(/\/.*$/, '')
      puts username
      fork = project.sub(username, Frankenstein.github_netrc_username)
      puts fork

      puts "\n#{logo} Creating GitHub client"
      client = Frankenstein.github_client

      puts "\n#{logo} Getting changes ... "
      f = client.pull_files project, number
      changes = f[0][:additions]
      m = 'Found '\
          "#{Frankenstein.pluralize2 changes, 'change'} "
      puts m

      puts "\n#{logo} Checking merge status for #{project.white} ..."
      merged = client.pull_merged? project, number
      puts 'Pull request was merged 🎉' if merged == true

      puts "\n#{logo} Checking pull request status ..." unless merged == true
      state = client.pull(project, number)[:state]
      puts 'Pull request was closed 😡' if state == 'closed' && merged == false

      check_comments(client, project, number, logo)

      puts ''
      if merged == true || state == 'closed'
        delete_fork(client, fork, logo)

        puts "\n#{logo} Crafting tweet ... \n\n"
        if (merged == true)
          t = "#{logo}#{clean_pull_url} was merged with "\
              "#{Frankenstein.pluralize2 changes, 'change'} "\
              "#{twitter_random_happy_emoji}"
        else # closed :-(
          t = "#{logo}This pull request with "\
              "#{Frankenstein.pluralize2 changes, 'change'} "\
              "looked pretty good ¯/_(ツ)_/¯ #{clean_pull_url}/files"
        end

        finish t, project, clean_pull_url
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

      m = "\n#{em_status_yellow} #{redirects.count} "\
          "#{pluralize 'redirect', redirects.count}"
      log.add m.yellow

      log.verbose "Replacing redirects in temp file #{file_updated}.."
      File.open(file_copy, 'a+') do |f|
        original = f.read
        replaced = original

        redirects.each do |hash|
          key, array = hash.first
          log.add "#{key.yellow} redirects to \n#{array} \n\n"
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
          m = "🔎  Checking #{links_to_check.count} ".white
          m << pluralize('link', links_to_check.count).white
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
            m = "\n🔎  Getting information for #{github_repos.count} GitHub "
            log.my_print m.white
            log.add pluralize('repo', github_repos.count).white

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
          m = "#{em_status_red} #{failures.count} "\
              "#{pluralize 'failure', failures.count} for #{argv1.blue}"
          log.add m.red
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

      failures
    end
  end # class
end
