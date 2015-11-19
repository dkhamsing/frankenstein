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

  OPTION_POPULAR = 'p'
  OPTION_RANDOM = 'r'
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
    a_po = OPTION_POPULAR.white
    m = "#{a_p} #{PRODUCT_DESCRIPTION.white} \n"\
        "Usage: #{a_p} <#{a_f}> "\
        "\n#{LEADING_SPACE} #{a_p} #{a_t} — scan trending repos"\
        "\n#{LEADING_SPACE} #{a_p} #{a_t} #{a_r} — scan trending repo for a "\
        'random language'\
        "\n#{LEADING_SPACE} #{a_p} #{a_t} [#{a_l}] — scan trending repo for a "\
        'given language '\
        "\n#{LEADING_SPACE} #{a_p} #{a_po} — scan trending repos for popular "\
        'languages'\
        "\n#{LEADING_SPACE} #{a_p} #{a_todo} - scan repos from #{'todo'.blue}"
    puts m
    puts "\n"
    exit
  end

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  Frankenstein.cli_create_log_dir

  class << self
    def core_scan(content)
      epoch = Time.now.to_i
      filename = "#{Frankenstein::FILE_LOG_DIRECTORY}/todo-#{epoch}"

      File.write filename, content

      Frankenstein.core_scan(filename)

      File.delete filename
    end

    def map_repos(repos)
      mapped = repos.map { |r| "https://github.com/#{r.name}" }

      m = ''
      mapped.each { |r| m << " #{r}" }

      m
    end
  end #class

  if argv_1 == OPTION_POPULAR
    all = []
    pop = POPULAR_LANGUAGES
    pop.each_with_index do |p, i|
      puts "#{i +1}/#{pop.count} Getting trending repos for #{p}"
      repos = Github::Trending.get p
      all = all + repos
    end

    core_scan map_repos(all)
    exit
  end

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

      core_scan m

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

    core_scan map_repos(repos)

    exit
  end

  unless File.exist? argv_1
    puts "#{PRODUCT.red} File #{argv_1.white} does not exist"
    exit(1)
  end

  Frankenstein.core_scan(argv_1)
end
