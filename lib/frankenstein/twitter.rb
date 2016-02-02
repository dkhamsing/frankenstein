# Tweets
module Frankenstein
  NETRC_TWITTER_CONSUMER = 'consumer.twitter'
  NETRC_TWITTER_ACCESS = 'access.twitter'

  HAPPY_EMOJIS = [
    '😎',
    '🎉',
    '😉',
    '😀',
    '😄',
    '😄',
    '☺️',
    '🙃',
    '👏'
  ]

  class << self
    require 'twitter'

    def twitter_frankenstein_tweet(project, gist_url, user_input, happy)
      t = "🏃 frankenstein for #{project} #{gist_url} #{user_input} "
      t << Frankenstein.twitter_random_happy_emoji if happy
      t
    end

    def twitter_client
      config = twitter_config
      Twitter::REST::Client.new(config)
    end

    def twitter_config
      n = Netrc.read
      consumer = n[NETRC_TWITTER_CONSUMER]
      access = n[NETRC_TWITTER_ACCESS]

      # TODO: netrc missing

      {
        consumer_key:        consumer[0],
        consumer_secret:     consumer[1],
        access_token:        access[0],
        access_token_secret: access[1]
      }
    end

    def twitter_log(message)
      puts "  🐦 Tweet sent: #{message.blue}"
    end

    def twitter_random_happy_emoji
      HAPPY_EMOJIS.sample
    end

    def twitter_tweet_url(client, tweet)
      username = client.current_user.screen_name
      "https://twitter.com/#{username}/status/#{tweet.id}"
    end
  end # class
end
