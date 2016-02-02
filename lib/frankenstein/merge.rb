# Check for merged pull request, close fork and send tweet
module Merge
  require 'colored'
  require 'frankenstein/constants'
  require 'frankenstein/core'
  require 'frankenstein/github'
  require 'frankenstein/output'

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

  # TODO: improve checking for pr url
  unless argv1.include? 'github.com'
    puts 'Oops not a pull request URL'.red
    exit
  end

  Frankenstein.core_merge argv1
end
