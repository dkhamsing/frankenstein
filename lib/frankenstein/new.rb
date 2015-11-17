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
  require 'json'
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
        print x.green + ' '
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
        # pp notif
        r = notif['repository']['name']
        thread = notif['id']
        user = Frankenstein.github_netrc_username
        repo = "#{user}/#{r}"

        json_url = notif['subject']['url']
        # puts json_url
        c = Frankenstein.net_get json_url
        # puts c.body.class
        json = JSON.parse c.body
        # pp json

        title = json['title']
        body = json['body']

        # puts title
        # puts body

        content = "#{title} #{body}"
        # puts content

        links_to_check, * = Frankenstein.core_find_links content

        match = content.match /.*\/.*/
        matched = match.to_s.split ' '
        matched = matched.select { |x| x.include? "/" }

        links_to_check = links_to_check + matched if matched.count > 0

        number = json['number']
        links_to_check.each do |x|
          item = {
            repo: x,
            issue: {
              repo: repo,
              number: number
            }
          }

          # puts item
          Frankenstein.core_todo_add item
          puts "Added #{x.white} to #{'todo'.blue}"

          # puts 'mark notification as read '

          # puts 'todo post a comment to ...'
          client = Frankenstein.github_client

          comment = "Issue processed, added #{x} to `todo`"

          client.add_comment repo, number, comment

          # success =
          client.mark_thread_as_read thread
          # pp success
        end # end links_to_check..
      end
    else
      exit
    end
  end # while

  puts "\n#{PRODUCT.white} finished " if n.count > 0
end # module
