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

  OPTION_RANDOM = 'random'
  OPTION_TREND = 't'
  OPTION_TODO = 'todo'

  POPULAR_LANGUAGES = [
    'java',
    'python',
    'php',
    'csharp',
    'c++',
    'c',
    'javascript',
    'objective-c',
    'swift',
    'r',
    'ruby',
    'perl',
    'matlab',
    'lua',
    'scala'
  ]

  argv_1, argv_2 = ARGV
  if argv_1.nil?
    a_p = PRODUCT.blue
    a_l = 'language'.green
    a_t = OPTION_TREND.white
    a_f = 'file'.white
    a_todo = OPTION_TODO.white
    a_r = OPTION_RANDOM.white
    m = "#{a_p} #{PRODUCT_DESCRIPTION.white} \n"\
        "Usage: #{a_p} <#{a_f}>"\
        "\n#{LEADING_SPACE} #{a_p} #{a_t} "\
        "\n#{LEADING_SPACE} #{a_p} #{a_t} #{a_r}"\
        "\n#{LEADING_SPACE} #{a_p} #{a_t} [#{a_l}]"\
        "\n#{LEADING_SPACE} #{a_p} #{a_todo} "
    puts m
    puts "\n"
    exit
  end

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  Frankenstein.cli_create_log_dir

  if argv_1 == OPTION_TODO
    f = Frankenstein::FILE_TODO
    todo = Frankenstein.io_json_read f

    left = todo.map { |x| x.dup }
    todo.each_with_index do |x, index|
      m = x['repo']

      unless m.include? '://github.com'
        m = "https://github.com/#{m}"
      end

      puts "Scanning #{m.white}..."
      epoch = Time.now.to_i
      filename = "#{Frankenstein::FILE_LOG_DIRECTORY}/todo-#{epoch}"

      File.write filename, m

      Frankenstein.core_scan(filename)

      File.delete filename

      left.delete_at 0
      Frankenstein.io_json_write f, left
      puts "todo left: #{left.count}"
      sleep 1
    end

    puts "Finished scanning #{todo.count} repos" unless todo.count == 0
    exit
  end

  if argv_1 == OPTION_TREND
    puts 'Scanning Trending in GitHub'

    if argv_2.nil?
      repos = Github::Trending.get
    elsif argv_2 == OPTION_RANDOM
      random_language = POPULAR_LANGUAGES.sample
      puts "Language: #{random_language.white}"
      repos = Github::Trending.get random_language
    else
      puts "Language: #{argv_2.white}"
      repos = Github::Trending.get argv_2
    end
    m = ''
    repos.each do |r|
      g_url = "https://github.com/#{r.name}"
      m << g_url + ' '
    end

    epoch = Time.now.to_i
    filename = "#{Frankenstein::FILE_LOG_DIRECTORY}/todo-#{epoch}"
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
