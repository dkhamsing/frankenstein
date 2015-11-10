# Check for merged pull request, close fork and send tweet
module Merge
  require 'colored'
  require 'frankenstein/constants'
  require 'frankenstein/github'
  require 'frankenstein/output'
  require 'frankenstein/twitter'

  # require 'pp'

  PRODUCT = 'mergeclose'
  PRODUCT_DESCRIPTION = 'Automate processing of merged pull requests'

  LEADING_SPACE = '     '

  argv1 = ARGV[0]
  if argv1.nil?
    m = "#{PRODUCT.blue} #{PRODUCT_DESCRIPTION.white} "\
        "\n#{LEADING_SPACE}"\
        "Usage: #{PRODUCT.blue} <#{'Pull request URL'.white}> "
    puts m
    puts "\n"
    exit
  end

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  # check for pr url
  unless argv1.include? 'github.com'
    puts 'Oops not a pull request URL'.red
    exit
  end

  class << self
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
  end # class

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
  puts 'Pull request was closed 😡' if state == 'closed'

  check_comments(client, project, number, logo)

  puts ''
  if merged == true || state == 'closed'
    delete_fork(client, fork, logo)

    puts "#{logo} Crafting tweet ... \n\n"
    if (merged == true)
      t = "#{logo}#{clean_pull_url} was merged with "\
          "#{Frankenstein.pluralize2 changes, 'change'} "\
          "#{Frankenstein.twitter_random_happy_emoji}"
    else
      t = "#{logo}This pull request with "\
          "#{Frankenstein.pluralize2 changes, 'change'} "\
          "looked pretty good ¯/_(ツ)_/¯ #{clean_pull_url}/files"
    end

    finish t, project, clean_pull_url
  else    
    puts 'Pull request is still open 📗'
  end
end
