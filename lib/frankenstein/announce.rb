# Create a gist from log
module Announce
  require 'colored'
  require 'frankenstein/github'
  require 'frankenstein/twitter'

  PRODUCT = 'announce'
  OPTION_HAPPY = '-h'
  OPTION_TWEET = 'tweet'

  LEADING_SPACE = '         '
  SPACE_ARGS    = "#{LEADING_SPACE} \t\t"

  argv1 = ARGV[0]
  if argv1.nil?
    m = "#{PRODUCT.blue} #{'Upload a log to GitHub gist'.white} "\
        "\n#{LEADING_SPACE}"\
        "Usage: #{PRODUCT.blue} <#{'file'.white}> "\
        "[#{OPTION_HAPPY.white}] "\
        "[#{OPTION_TWEET.white} message] \n"\
        "#{SPACE_ARGS} #{OPTION_TWEET} \t Tweet a message (optional) \n"\
        "#{SPACE_ARGS} #{OPTION_HAPPY} \t Make the tweet happy 🎉 \n"\
        "\n#{LEADING_SPACE}"\
        "#{PRODUCT} requires credentials in .netrc "
    puts m
    puts "\n"
    exit
  end

  if !Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  option_tweet = ARGV.include? OPTION_TWEET

  if option_tweet
    creds = Frankenstein.twitter_config
    if creds.nil?
      puts 'Missing Twitter credentials in .netrc'.red
      exit(1)
    end
  end

  unless File.exist? argv1
    puts "#{PRODUCT.red} File #{argv1.white} does not exist"
    exit(1)
  end

  gist_url, filename = Frankenstein.github_create_gist argv1, true

  if option_tweet
    client = Frankenstein.twitter_client

    separator = '-'
    a = filename.split separator
    project = a[4..a.count].join(separator).sub(separator, '/')
    fr = 'frankenstein'
    project = project.gsub(fr, '')[0...-1] if project.include? fr

    user_input = ARGV[2..ARGV.count].join ' '

    happy = ARGV.include? OPTION_HAPPY
    tweet = Frankenstein.twitter_frankenstein_tweet(project, gist_url,
                                                    user_input, happy)
    t = client.update tweet

    Frankenstein.twitter_log Frankenstein.twitter_tweet_url(client, t)
  end
end
