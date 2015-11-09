# Check for merged pull request, close fork and send tweet
module Closed
  require 'colored'
  require 'frankenstein/constants'
  require 'frankenstein/github'
  require 'frankenstein/output'
  require 'frankenstein/twitter'

  PRODUCT = 'closed'
  PRODUCT_DESCRIPTION = 'Automate processing of closed pull requests'

  argv1 = ARGV[0]
  if argv1.nil?
    m = "#{PRODUCT.blue} #{PRODUCT_DESCRIPTION.white} \n"\
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

  puts "\n#{logo} Checking merge status for #{project.white} ..."
  client = Frankenstein.github_client

  puts "\n#{logo} Checking comments ..."
  comments = client.issue_comments project, number
  puts 'No comments' if comments.count == 0
  unless comments == 0
    comments.each do |c|
      u = '@' << c[:user][:login]
      m = "\n#{u.white}: #{c[:body]} "
      puts m
    end
  end

  puts "\n#{logo} Deleting fork #{fork} ..."
  client.delete_repository fork

  f = client.pull_files project, number
  changes = f[0][:additions]

  puts "\n#{logo} Crafting tweet ... \n"
  t = "#{logo}This pull request with "\
      "#{Frankenstein.pluralize2 changes, 'change'} "\
      "looked pretty good ¯/_(ツ)_/¯ "\
      "#{clean_pull_url}/files"
  puts t

  client = Frankenstein.twitter_client
  t = client.update t

  puts "\nTweet sent #{Frankenstein.twitter_tweet_url(client, t).blue}"

  puts "\n#{PRODUCT} finished for #{project.white}"
end
