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

  LEADING_SPACE = '     '
  OPTION_TREND = 't'

  argv_1 = ARGV[0]
  if argv_1.nil?
    blue = PRODUCT.blue
    m = "#{blue} #{PRODUCT_DESCRIPTION.white} "\
        "\n#{LEADING_SPACE}"\
        "Usage: #{blue} <#{'file'.white}> "\
        "\n#{LEADING_SPACE}       #{blue} #{OPTION_TREND.white}"
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

    repos = Github::Trending.get
    m = ''
    repos.each do |r|
      g_url = "https://github.com/#{r.name}"
      m << g_url + ' '
    end

    filename = "#{Frankenstein::FILE_LOG_DIRECTORY}/todo"
    puts "Creating temp file #{filename.white}"
    File.write filename, m

    Frankenstein.core_scan(filename)

    puts 'Deleting temp file'
    File.delete filename
    exit
  end

  unless File.exist? argv_1
    puts "#{PRODUCT.red} File #{argv_1.white} does not exist"
    exit(1)
  end

  Frankenstein.core_scan(argv_1)
end
