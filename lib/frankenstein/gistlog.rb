# Create a gist from log
module GistLog
  require 'colored'
  require 'frankenstein/github'
  require 'frankenstein/twitter'

  PRODUCT = 'gistlog'
  OPTION_TWEET = 'tweet'
  LEADING_SPACE = '        '

  argv1 = ARGV[0]
  if argv1.nil?
    m = "#{PRODUCT.blue} #{'Upload a log to GitHub gist'.white} \n"\
        "#{LEADING_SPACE}"\
        "Usage: #{PRODUCT.blue} <#{'file'.white}> "\
        "[#{OPTION_TWEET.white} message] \n"\
        "#{LEADING_SPACE}       "\
        "tweeting is optional \n\n"\
        "#{LEADING_SPACE}"\
        "#{PRODUCT} requires credentials in .netrc "
    puts m
    puts "\n"
    exit
  end

  option_tweet = ARGV.include? OPTION_TWEET

  creds = Frankenstein.github_netrc
  if creds.nil?
    puts 'Missing GitHub credentials in .netrc'.red
    exit(1)
  end

  if option_tweet
    creds = Frankenstein.twitter_config
    if creds.nil?
      puts 'Missing Twitter credentials in .netrc'.red
      exit(1)
    end
  end

  unless File.exist? argv1
    puts "File #{argv1.white} does not exist"
    exit(1)
  end

  gist_url, filename = Frankenstein.github_create_gist argv1, true

  if option_tweet
    client = Frankenstein.twitter_client
    separator = '-'
    a = filename.split separator
    project = a[4..a.count].join(separator).gsub('frankenstein', '')[0...-1]
              .sub('-', '/')

    m = 'Add to the tweet (@ mention, comment): '
    print m
    user_input = STDIN.gets.chomp

    tweet = "🏃 frankenstein for #{project} #{gist_url} " << user_input
    t = client.update tweet

    username = client.current_user.screen_name
    tweet_url = "https://twitter.com/#{username}/status/#{t.id}"
    puts "  🐦 Tweet sent #{tweet_url.blue}"
  end
end
