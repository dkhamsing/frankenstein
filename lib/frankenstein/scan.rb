# Scan for GitHub repos
module Scan
  require 'colored'
  require 'github-trending'

  require 'frankenstein/cli'
  require 'frankenstein/constants'
  require 'frankenstein/core'
  require 'frankenstein/github'

  PRODUCT = 'scan'
  PRODUCT_DESCRIPTION = 'Scan for GitHub repos'

  LEADING_SPACE = '      '
  OPTION_TREND = 't'

  argv_1, argv_2 = ARGV
  if argv_1.nil?
    a_p = PRODUCT.blue
    a_l = 'language'.green
    a_t = OPTION_TREND.white
    a_f = 'file'.white
    m = "#{a_p} #{PRODUCT_DESCRIPTION.white} \n"\
        "Usage: #{a_p} <#{a_f}>"\
        "\n#{LEADING_SPACE} #{a_p} #{a_t} "\
        "\n#{LEADING_SPACE} #{a_p} #{a_t} [#{a_l}]"
    puts m
    puts "\n"
    exit
  end

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  Frankenstein.cli_create_log_dir

  if argv_1 == OPTION_TREND
    puts 'Scanning Trending in GitHub'
    puts "Language: #{argv_2}" unless argv_2.nil?

    if argv_2.nil?
      repos = Github::Trending.get
    else
      repos = Github::Trending.get argv_2
    end
    m = ''
    repos.each do |r|
      g_url = "https://github.com/#{r.name}"
      m << g_url + ' '
    end

    filename = "#{Frankenstein::FILE_LOG_DIRECTORY}/todo"
    puts "Creating temp file #{filename.white}"
    File.write filename, m

    Frankenstein.core_scan(filename)

    puts "Deleting temp file #{filename.white}"
    File.delete filename
    exit
  end

  unless File.exist? argv_1
    puts "#{PRODUCT.red} File #{argv_1.white} does not exist"
    exit(1)
  end

  Frankenstein.core_scan(argv_1)
end
