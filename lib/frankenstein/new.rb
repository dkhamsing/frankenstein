# Check GitHub notifications
module New
  require 'colored'
  require 'frankenstein/constants'
  require 'frankenstein/github'
  require 'frankenstein/output'

  require 'pp'

  PRODUCT = 'new'
  # OPTION_MERGE = 'm'

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  # argv1 = ARGV[0]
  # state = argv1 == OPTION_MERGE ? 'merged' : 'open'

  puts '> Creating GitHub client'
  client = Frankenstein.github_client

  puts '> Getting notifications'

  n = client.notifications

  pp n

  n.each_with_index do |x, index|
    s = x[:subject]
    u = s[:url]
    pull_url = u.sub('api.', '').sub('repos/', '').sub('/pulls', '/pull')

    puts "#{index+1} #{pull_url.blue}"
  end

  puts Frankenstein.pluralize2 n.count, 'notification'

  t = Time.new.strftime('%b %d at %I:%M%p')
  puts "No notifications #{t.white}" if n.count == 0

  # TODO: prompt to merge..
end
