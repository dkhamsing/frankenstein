# Tweets
module Frankenstein
  NETRC_TWITTER_CONSUMER = 'consumer.twitter'
  NETRC_TWITTER_ACCESS = 'access.twitter'

  class << self
    require 'twitter'

    def twitter_client
      config = twitter_config
      Twitter::REST::Client.new(config)
    end

    def twitter_config
      n = Netrc.read
      consumer = n[NETRC_TWITTER_CONSUMER]
      access = n[NETRC_TWITTER_ACCESS]

      # return nil unless consumer.nil?
      # return nil unless access.nil?

      {
        consumer_key:        consumer[0],
        consumer_secret:     consumer[1],
        access_token:        access[0],
        access_token_secret: access[1]
      }
    end
  end # class
end
