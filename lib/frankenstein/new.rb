# Extend string
class String
  def number?
    true if Float(self)
  rescue
    false
  end
end

# Check GitHub notifications
module New
  require 'colored'
  # require 'pp'
  require 'frankenstein/constants'
  require 'frankenstein/core'
  require 'frankenstein/github'
  require 'frankenstein/output'

  PRODUCT = 'new'

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  puts '> Creating GitHub client'
  client = Frankenstein.github_client

  puts '> Getting notifications'
  n = client.notifications
  # pp n

  m = n.map do |x|
    s = x[:subject]
    u = s[:url]
    u.sub('api.', '').sub('repos/', '').sub('/pulls', '/pull')
    # is it better to load `u` and retrieve html_url via json ?
  end

  t = Time.new.strftime('%b %d at %I:%M%p')
  puts "#{'No notifications'.green} #{t.white}" if n.count == 0

  while m.count > 0
    m.each_with_index do |x, index|
      puts "#{index + 1} #{x.blue}"
    end

    print '> Enter number to merge pull request: '
    user_input = STDIN.gets.chomp
    puts user_input

    if user_input.number?
      index = user_input.to_i - 1
      url_to_merge = m[index]
      m.delete_at(index)
      puts url_to_merge

      Frankenstein.core_merge url_to_merge
    else
      puts 'not a number'
    end
  end

  puts "\n#{PRODUCT.white} finished " if n.count > 0
end # module
