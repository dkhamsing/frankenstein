# Process cli: command line interface
module Frankenstein
  class << self
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
        FLAG_FAIL,
        FLAG_MINIMIZE_OUTPUT,
        FLAG_GITHUB_STARS,
        FLAG_VERBOSE
      ]
    end
  end # class
end
