# Facilitate creating pull requests to update redirects
module Review
  require 'colored'

  require 'frankenstein/cli'
  require 'frankenstein/constants'
  require 'frankenstein/core'
  require 'frankenstein/github'
  require 'frankenstein/io'
  require 'frankenstein/log'

  PRODUCT = 'review'
  PRODUCT_DESCRIPTION = 'Facilitate creating pull requests to update redirects'

  OPTION_ALL = 'all'
  OPTION_DONE = 'done'
  OPTION_LOG = 'logs'

  argv_1, argv_2, * = ARGV
  if argv_1.nil?
    o_p = PRODUCT.blue
    o_n = 'n'.white
    m = "#{o_p} #{PRODUCT_DESCRIPTION.white} \n"\
        "Usage: #{o_p} <#{'file'.white}> \n"\
        "       #{o_p} #{OPTION_LOG.blue} \n"\
        "       #{o_p} #{OPTION_LOG.blue} #{OPTION_ALL.blue} \n"\
        "       #{o_p} #{OPTION_LOG.blue} <#{o_n}> or \n"\
        "       #{o_p} <#{o_n}> \n"\
        "       #{o_p} <#{o_n}> #{OPTION_DONE.blue} \n"\
        "       #{o_p} #{OPTION_LOG.blue} #{OPTION_DONE.blue} \n"
    puts m
    exit
  end

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  class << self
    def mark_done(repo)
      puts "#{repo.white} marked as done"
    end
  end

  if (argv_1 == OPTION_LOG) && (argv_2.nil?)
    r = Frankenstein.io_records(argv_2 == OPTION_ALL)

    if argv_2 == OPTION_DONE
      m = r.map { |key, _| key }
      # puts m
      m.each_with_index do |x|
        mark_done x
        Frankenstein.io_record_review x
      end
      puts 'Finished'
      exit
    end

    idx = 0
    r.each do |key, value|
      idx += 1
      puts "#{idx} #{key}".white 
      list = value['log']
      list.each_with_index do |x, index|
        if list.count > 1
          head = "#{index + 1}. "
          if x['type'] == 'pull'
            print head.red
            # print 'pull '.red
          else
            print head
          end
        end

        type = x['type']
        type = type.red if type == 'pull'
        print "#{type} "

        if type == 'visit'
          r = x['redirects'] if type
          print "#{r.to_s.yellow} " if r > 2
        end
        puts x
      end
    end

    puts 'Log is empty 🎉' if idx == 0

    exit
  end

  number = if argv_1 == OPTION_LOG
             argv_2.to_i
           else
             argv_1.to_i
           end

  if number > 0
    r = Frankenstein.io_records false

    if number > r.count
      puts "No log matching index #{argv_1.red}"
      exit 1
    end

    idx = 0
    s = r.select do |x|
      idx += 1
      x if idx == number
    end
    argv_1 = s.keys[0]

    if argv_2 == OPTION_DONE
      mark_done argv_1
      Frankenstein.io_record_review argv_1
      exit
    end
  end

  # read repo from log
  if argv_1.count('/') == 1
    r = Frankenstein.io_json_read Frankenstein::FILE_VISITS
    if r.key? argv_1
      events = r[argv_1]['log']
      visit = events.select { |x| x['type'] == 'visit' }[0]
      argv_1 = visit['file']
      puts argv_1
    end
  end

  logs_dir = Frankenstein::FILE_LOG_DIRECTORY
  file_redirects = "#{logs_dir}/temp-r"
  file_updated = "#{logs_dir}/temp-u"
  file_log = "#{logs_dir}/temp-log"

  # filter stats files
  argv_1 = argv_1.gsub(/-stats.*$/, '')
  argv_1 = "#{logs_dir}/#{argv_1}" if
    !(argv_1.include? logs_dir) && !(File.exist? argv_1)

  # check the files below exist
  file_copy = "#{argv_1}-copy"
  file_info = "#{argv_1}-info"
  redirects_file = "#{argv_1}-redirects"

  if not File.exist? file_copy or
     not File.exist? file_info or
     not File.exist? redirects_file
    puts 'Error: File(s) missing'.red
    exit
  end

  puts "Processing for ... \n#{argv_1.white}"
  puts "#{file_copy.white} file_copy"
  puts "#{file_info.white} file_info"
  puts "#{redirects_file.white} redirects_file"

  # c = File.read(redirects_file)
  redirects = Frankenstein.io_json_read redirects_file

  info = Frankenstein.io_json_read file_info
  # puts info

  argv1 = info['repo']

  default_branch = info['branch']
  readme = info['readme']

  log = Frankenstein::Log.new(false, file_log)

  done = nil
  while done.nil?
    Frankenstein.core_process_redirects(
      file_redirects,
      file_copy,
      file_updated,
      redirects,
      log)

    option_pull = 'p'
    option_white_list = 'w'
    user_input = Frankenstein.cli_prompt option_pull, option_white_list
    if user_input.downcase == option_pull
      log.add "\nCreating pull request on GitHub for #{argv1} ...".white

      desc = Frankenstein.github_pull_description(redirects, nil)
      p = Frankenstein.github_pull_request(argv1, default_branch, readme,
                                           file_updated, desc, log)
      log.add "Pull request created: #{p.blue}".white
      Frankenstein.io_record_pull(argv1, p)

      done = true
    elsif user_input.include? option_white_list
      wl = user_input.sub("#{option_white_list}=", '')
      list = wl.split '^'

      list.each do |x| # TODO: this looks like it could be improved
        redirects.reject! do |hash|
          key, * = hash.first
          key.include? x
        end
      end
    else
      done = true
    end
  end # end while

  Frankenstein.io_record_review argv1
end
