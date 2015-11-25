# Gather comments...
module Comments
  require 'colored'

  require 'frankenstein/constants'
  require 'frankenstein/github'
  require 'frankenstein/io'
  require 'frankenstein/output'

  FILE = "#{Frankenstein::FILE_LOG_DIRECTORY}/franken_comments.json"

  PRODUCT = 'comments'
  PRODUCT_DESCRIPTION = 'Gather comments on merged issues'

  OPTION_GET = 'get'
  OPTION_READ = 'read'
  OPTION_ALL = 'all'

  LEADING_SPACE = '  '

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  argv1, argv2 = ARGV

  if argv1.nil?
    u_p = PRODUCT.blue
    u_d = PRODUCT_DESCRIPTION.white
    o_g = OPTION_GET.white
    o_r = OPTION_READ.white
    o_a = OPTION_ALL.white
    m = "#{u_p} #{u_d} \n"\
        "#{LEADING_SPACE}"\
        "Usage: #{u_p} #{o_g} - get latest\n"\
        "#{LEADING_SPACE}       "\
        "#{u_p} #{o_g} #{o_a} - get all \n"\
        "#{LEADING_SPACE}       "\
        "#{u_p} #{o_r} "
    puts m
    exit
  end

  if File.exist? FILE
    puts "Reading #{FILE.white}"
    json = Frankenstein.io_json_read FILE
  end

  if argv1 == OPTION_READ
    exit unless File.exist? FILE

    json.reject { |y| y.values[0]['number_of_comments'] == 0 }
      .each_with_index do |x, i|
        project = x.keys[0]
        puts "#{i + 1} #{project.white}"

        c = x.values[0]['comments']
        c.each do |d|
          # pp c
          cr = d['created_at']
          up = d['updated_at']

          m = " #{d['body']} — @#{d['login']}"

          if cr == up
            puts m
          else
            puts m + ' (updated)'.red
          end
        end
      end
    exit
  end

  class << self
    def project_from_issue(i)
      x = pull_url i
      project_from_url x
    end

    def project_from_url(x)
      x.gsub(/\/pull.*$/, '').sub('https://github.com/', '')
    end

    def pull_url(y)
      y[:pull_request][:html_url]
    end
  end

  if argv1 == OPTION_GET
    puts '> Creating GitHub client'
    client = Frankenstein.github_client
    client.auto_paginate = true if argv2 == OPTION_ALL

    state = 'merged'
    puts "> Getting #{state} issues"
    i = Frankenstein.github_issues client, state

    issues = i[:items]
    puts "Got #{issues.count} items "

    unless json.nil?
      keys = json.map { |x| x.keys[0] }

      issues = issues.reject do |y|
        project = project_from_issue y
        condition = keys.include? project
        puts "Skipping #{project.white}" if condition

        condition
      end
    end

    map = issues.each_with_index.map do |y, i2|
      project = project_from_issue y
      number = y[:number]

      begin
        comments = client.issue_comments project, number
        # pp comments
      rescue StandardError => e
        puts "Error getting comments #{e}".red
        next
      end

      m = "#{i2} #{project.white} #{comments.count} comments"
      puts m

      cm = comments.map do |z|
        {
          login: z['user']['login'],
          created_at: z['created_at'],
          updated_at: z['updated_at'],
          body: z['body']
        }
      end

      sleep 0.8
      { project =>
        {
          url: y,
          comments: cm,
          number_of_comments: comments.count
        }
      }
    end

    f = map
    f = map.concat json unless json.nil?
    Frankenstein.io_json_write FILE, f
    puts "Wrote log to #{FILE.white}"
  end
end # module
