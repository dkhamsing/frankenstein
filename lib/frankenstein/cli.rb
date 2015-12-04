# Process cli: command line interface
module Frankenstein
  class << self
    def cli_create_log_dir
      Dir.mkdir FILE_LOG_DIRECTORY unless File.exist?(FILE_LOG_DIRECTORY)
    end

    def cli_filter_github(argv1)
      repo = argv1.gsub(%r{https?:\/\/github.com\/}, '')
      ((repo.count '/').to_i == 1) ? repo : argv1
    end

    def cli_get_github(option_github_stars_only, argv_flags)
      if option_github_stars_only
        true
      else
        argv_flags.to_s.include? FLAG_GITHUB_STARS
      end
    end

    def cli_option_value(name, separator, log)
      temp = cli_option_value_raw name, separator, log
      temp ? temp.to_i : nil
    end

    def cli_option_value_raw(name, separator, log)
      regex = "#{name}#{separator}"
      log.verbose "Regular expression: #{regex}"
      temp = ARGV.find { |e| /#{regex}/ =~ e }

      temp ? temp.split(separator)[1] : nil
    end

    def cli_all_flags
      [
        FLAG_MINIMIZE_OUTPUT,
        FLAG_VERBOSE,
        FLAG_GITHUB_STARS
      ]
    end

    def cli_log(argv_flags)
      argv_flags.to_s.include? FLAG_VERBOSE
    end

    def cli_process_flags(option_github_stars_only, argv_flags)
      flag_fetch_github_stars = cli_get_github(option_github_stars_only,
                                               argv_flags)
      flag_minimize_output = argv_flags.to_s.include? FLAG_MINIMIZE_OUTPUT

      [
        flag_fetch_github_stars,
        flag_minimize_output,
      ]
    end

    def cli_process_options(log)
      option_github_stars_only = ARGV.include? OPTION_STARS
      option_head = ARGV.include? OPTION_HEAD
      option_white_list = cli_option_value_raw OPTION_WHITE_LIST, SEPARATOR, log

      [
        option_github_stars_only,
        option_head,
        option_white_list
      ]
    end

    def cli_process_misc(argv1, log)
      argv1_is_http = argv1.match(/^http/)

      unless argv1_is_http
        begin
          found_file_content = File.read(argv1)
        rescue StandardError => e
          log.verbose "Not a file: #{e.to_s.red}"
        end
      end

      number_of_threads = cli_option_value OPTION_THREADS, SEPARATOR, log
      number_of_threads = DEFAULT_NUMBER_OF_THREADS if number_of_threads.nil?

      [
        argv1_is_http,
        found_file_content,
        number_of_threads
      ]
    end

    def cli_process(argv1, argv_flags, log)
      argv1_is_http,
      found_file_content,
      number_of_threads = cli_process_misc(argv1, log)

      option_github_stars_only,
      option_head,
      option_white_list = cli_process_options(log)

      flag_fetch_github_stars,
      flag_minimize_output = cli_process_flags(option_github_stars_only,
                                               argv_flags)

      [
        option_github_stars_only,
        option_head,
        option_white_list,
        flag_fetch_github_stars,
        flag_minimize_output,
        argv1_is_http,
        found_file_content,
        number_of_threads
      ]
    end

    def cli_prompt(option_pull, option_white_list)
      m = "\nCreate pull request? (#{option_pull.white}ull request | "\
          "white list #{option_white_list.white}=s1^s2.. | "\
          'enter to end) '
      print m
      STDIN.gets.chomp
    end
  end # class
end
