# Check GitHub issues
module Issues
  require 'colored'
  require 'frankenstein/constants'
  require 'frankenstein/github'
  require 'frankenstein/output'

  # require 'pp'
  PRODUCT = 'issues'
  OPTION_MERGE = 'm'

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  argv1 = ARGV[0]
  state = argv1 == OPTION_MERGE ? 'merged' : 'open'

  puts '> Creating GitHub client'
  client = Frankenstein.github_client

  puts '> Getting issues'
  q = "is:#{state} is:pr author:#{Frankenstein.github_netrc_username}"
  i = client.search_issues q

  count = i[:total_count]
  m = Frankenstein.pluralize2 count, 'issue'
  puts count == 0 ? 'No issues' : m

  items = i[:items]
  items.each_with_index do |x, index|
    pull_url = x[:html_url]
    m = "#{index + 1} #{pull_url.blue}"
    puts m
  end

  puts "\nUse #{PRODUCT.white} #{OPTION_MERGE.white} for merged pull "\
       'requests' unless argv1 == OPTION_MERGE
end
