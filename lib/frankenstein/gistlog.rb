# Create a gist from log
module GistLog
  require 'colored'
  require 'frankenstein/github'

  PRODUCT = 'gistlog'

  argv1 = ARGV[0]
  if argv1.nil?
    m = "#{PRODUCT.blue} Upload a log to GitHub gist \n        "\
        "Usage: #{PRODUCT.blue} <#{'file'.white}>"
    puts m
    exit
  end

  creds = Frankenstein.github_netrc
  if creds.nil?
    puts 'Missing GitHub credentials in .netrc'.red
    exit(1)
  end

  Frankenstein.github_create_gist argv1, true
end
