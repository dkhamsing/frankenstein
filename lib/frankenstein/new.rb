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
  # require 'json'
  require 'frankenstein/constants'
  require 'frankenstein/core'
  require 'frankenstein/network'
  require 'frankenstein/github'
  require 'frankenstein/output'

  PRODUCT = 'new'
  RUN_ISSUES = '/Run/issues/'

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
      print "#{index + 1}  "
      if x.include? RUN_ISSUES
        notif = n[index]
        subject = notif['subject']['title']
        print x.yellow + ' '
        puts subject
      else
        puts x.blue
      end
    end

    print '> Enter number to process (or enter to exit): '
    user_input = STDIN.gets.chomp
    puts user_input

    if user_input.number?
      index = user_input.to_i - 1

      url = m[index]
      m.delete_at(index)
      puts url

      unless url.include? RUN_ISSUES
        Frankenstein.core_merge url
      else
        notif = n[index]

        r = notif['repository']['name']
        user = Frankenstein.github_netrc_username
        repo = "#{user}/#{r}"

        j = notif['subject']['url']

        links_to_check, json = Frankenstein.core_links_to_check repo, j

        number = json['number']
        links_to_check.each do |x|
          item = {
            repo: x,
            # might not need issue hash
            issue: {
              repo: repo,
              number: number
            }
          }

          Frankenstein.core_todo_add item
          puts "Added #{x.white} to #{'todo'.blue}"

          client = Frankenstein.github_client

          comment = "Run request for #{x} received."
          client.add_comment repo, number, comment

          thread = notif['id']
          client.mark_thread_as_read thread
        end # end links_to_check..
      end
    else
      exit
    end
  end # while

  puts "\n#{PRODUCT.white} finished " if n.count > 0
end # module
