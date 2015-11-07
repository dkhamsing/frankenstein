# Create a gist from log
module Announce
  require 'colored'
  require 'frankenstein/github'
  require 'frankenstein/twitter'

  PRODUCT = 'check_merge'
  PRODUCT_DESCRIPTION = 'Check for merged pull request'
  # OPTION_HAPPY = '-h'
  # OPTION_TWEET = 'tweet'

  LEADING_SPACE = '     '
  # SPACE_ARGS    = "#{LEADING_SPACE} \t\t"

  argv1 = ARGV[0]
  if argv1.nil?
    m = "#{PRODUCT.blue} #{PRODUCT_DESCRIPTION.white} "\
        "\n#{LEADING_SPACE}"\
        "Usage: #{PRODUCT.blue} <#{'fork'.white}> "
    puts m
    puts "\n"
    exit
  end
end
