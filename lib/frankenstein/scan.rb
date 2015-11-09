# Scan for GitHub repos
module Scan
  require 'colored'
  require 'parallel'

  require 'frankenstein/constants'
  require 'frankenstein/core'
  require 'frankenstein/github'
  require 'frankenstein/log'
  require 'frankenstein/network'
  require 'frankenstein/output'

  PRODUCT = 'scan'
  PRODUCT_DESCRIPTION = 'Scan for GitHub repos'

  LEADING_SPACE = '     '

  argv_1 = ARGV[0]
  if argv_1.nil?
    m = "#{PRODUCT.blue} #{PRODUCT_DESCRIPTION.white} "\
        "\n#{LEADING_SPACE}"\
        "Usage: #{PRODUCT.blue} <#{'file'.white}> "
    puts m
    puts "\n"
    exit
  end

  if !Frankenstein.github_creds
    puts 'Missing GitHub credentials in .netrc'
    exit(1)
  end

  unless File.exist? argv_1
    puts "#{PRODUCT.red} File #{argv1.white} does not exist"
    exit(1)
  end

  c = File.read argv_1
  links, * = Frankenstein.core_find_links c
  r = Frankenstein.github_get_repos links
  # puts r
  puts "Scanning #{Frankenstein.pluralize2(r.count, 'repo').white}"

  flag_verbose = false
  number_of_threads = 10
  d = Dir.entries(Frankenstein::FILE_LOG_DIRECTORY)
  logs = d.join ''
  r.each do |argv1|
    next if logs.include? argv1.sub('/', '-')

    elapsed_time_start = Time.now

    log = Frankenstein::Log.new(flag_verbose, argv1)

    file_copy = log.filename(Frankenstein::FILE_COPY)
    file_updated = log.filename(Frankenstein::FILE_UPDATED)
    file_redirects = log.filename(Frankenstein::FILE_REDIRECTS)
    file_log = log.filelog

    message, parsed = Frankenstein.github_repo_unauthenticated(argv1, log)
    if message == 'Not Found' || message == 'Moved Permanently'
      m = "Retrieving repo #{argv1} "
      log.error "#{m.red} #{message.downcase}"
      next
    elsif message.include? 'API rate limit exceeded'
      log.error "GitHub #{message}"
      log.add 'Finding readme...'

      default_branch = 'master'
      the_url, * = Frankenstein.net_find_github_url_readme(argv1,
                                                           default_branch)
    else
      default_branch = parsed['default_branch']
      log.add Frankenstein.github_repo_json_info(parsed,
                                                 default_branch,
                                                 argv1)
      the_url, * = Frankenstein.net_find_github_url_readme(argv1,
                                                           default_branch)
    end # if message ..

    content = Frankenstein.net_get(the_url).body
    File.open(file_copy, 'w') { |f| f.write(content) }

    links_to_check, * = Frankenstein.core_find_links content

    Frankenstein.core_run(
      elapsed_time_start,
      log,
      links_to_check,
      argv1,
      number_of_threads,
      false, # option_github_stars_only,
      true,  # option_head,
      false, # option_white_list,
      false, # flag_control_failure,
      false, # flag_minimize_output,
      false, # flag_fetch_github_stars,
      file_redirects,
      file_updated,
      file_copy,
      file_log)
  end # Parallel
end
