# Extend string
class String
  def number?
    true if Float(self)
  rescue
    false
  end
end

# Check GitHub issues
module Issues
  require 'colored'
  # require 'pp'

  require 'frankenstein/constants'
  require 'frankenstein/core'
  require 'frankenstein/github'
  require 'frankenstein/io'
  require 'frankenstein/output'

  PRODUCT = 'issues'
  OPTION_MERGE = 'm'
  OPTION_OPEN = 'o'
  RUN_REPO = 'Run'

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  argv1 = ARGV[0]
  if argv1 == OPTION_OPEN
    puts "Open issues in #{RUN_REPO}"

    client = Frankenstein.github_client
    repo = "#{Frankenstein.github_netrc_username}/#{RUN_REPO}"
    i = client.list_issues repo

    while i.count > 0
      i.each_with_index do |x, index|
        url = x['html_url']
        title = x['title']
        puts " #{index + 1} #{url.blue} #{title}"
      end

      print '> Enter number to process (or enter to exit): '
      user_input = STDIN.gets.chomp

      exit unless user_input.number?

      index = user_input.to_i - 1

      n = i[index]
      i.delete_at(index)

      j = n['url']
      links_to_check, json = Frankenstein.core_links_to_check RUN_REPO, j

      number = json['number']

      logs = Frankenstein.io_json_read Frankenstein::FILE_VISITS

      pulls = []
      left = links_to_check.reject do |x|
        m = logs.map do |key, value|
          found = false

          if x.include? key
            log = value['log']
            found = log.map { |y| y['type'] }.include? 'visit'

            pull = log.select { |y| y['pull_url'] if y['type'] == 'pull' }
            pulls.push pull[0]['pull_url'] if pull.count > 0
          end

          found
        end

        m.include? true
      end

      if left.count == 0
        comment = "`frankenstein` run complete for "\
                  "#{Frankenstein.pluralize2 links_to_check, 'repo'} \n"
        pulls.each do |x|
          filtered = x.gsub(/\/pull\/.*/, '')
          pull_num = x.sub(filtered, '').sub('/pull/', '')
          p_text = "#{filtered}/pulls `#{pull_num}`"
          comment << "- created pull request for #{p_text} \n"
        end

        client.add_comment repo, number, comment
        puts 'Left a comment on GitHub'

        client.close_issue repo, number
        puts "GitHub issue #{number} closed"
      else
        puts "Still have to run frankenstein for "
        left.each_with_index { |x, idx| puts "#{idx + 1} #{x.white}"}
      end

    end #while
    exit
  end

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

  m = "\nUse #{PRODUCT.white} #{OPTION_MERGE.white} for merged pull requests \n"\
      "Use #{PRODUCT.white} #{OPTION_OPEN.white} for open issues in #{RUN_REPO}"

  puts m unless argv1 == OPTION_MERGE

end
