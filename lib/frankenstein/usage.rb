require 'frankenstein/constants'
require 'frankenstein/emoji'

# Usage
module Frankenstein
  require 'colored'

  class << self
    def all_argv1
      "#{ARGV1_URL.magenta}|#{ARGV1_FILE.magenta}|"\
        "#{ARGV1_GITHUB_REPO.magenta}"
    end

    def all_flags
      FLAG_FAIL +
        FLAG_MINIMIZE_OUTPUT +
        FLAG_GITHUB_STARS.yellow +
        FLAG_VERBOSE
    end

    def usage
      m = "#{em_logo} #{'Check for live URLS on a page'.white} \n" \
          "#{PRODUCT.green} <#{all_argv1}> "\
      "[-#{all_flags.blue}] "\
      "[#{OPTION_LOG.blue}] "\
      "[#{OPTION_PULL_REQUEST.blue}] "\
      "[#{OPTION_STARS.yellow}] "\
      "[#{OPTION_ROW.blue}=d] "\
      "[#{OPTION_THREADS.blue}=d] "\
      "\n"\
      "   #{ARGV1_URL.magenta} \t\t URL for the page \n"\
      "   #{ARGV1_GITHUB_REPO.magenta} \t GitHub repository \n"\
      "   #{ARGV1_FILE.magenta} \t File on disk \n\n"\
      "   #{FLAG_FAIL.blue} \t\t Add a controlled failure \n"\
      "   #{FLAG_MINIMIZE_OUTPUT.blue} \t\t Minimized result output "\
      "(see row option below) \n"\
      "   #{FLAG_GITHUB_STARS.yellow} \t\t Get GitHub repo info \n"\
      "   #{FLAG_VERBOSE.blue} \t\t Verbose output \n"\
      "\n   #{OPTION_LOG.blue} \t\t Write log to file \n"\
      "   #{OPTION_PULL_REQUEST.blue} \t Create a pull request with updated "\
      "redirects \n"\
      "   #{OPTION_STARS.yellow} \t Get GitHub repo info only \n"\
      "   #{OPTION_ROW.blue} \t\t Number of items per row (minimized output, "\
      "#{DEFAULT_NUMBER_OF_ITEMS_PER_ROWS} is the default, only works "\
      "with threads=0) \n"\
      "   #{OPTION_THREADS.blue} \t Number of parallel threads "\
      "(#{DEFAULT_NUMBER_OF_THREADS} is the default) \n"\
      "\n"\
      "\n#{em_logo} #{'Examples'.white} \n"\
      "$ #{PRODUCT} https://fastlane.tools \n"\
      "$ #{PRODUCT} README.md \n"\
      "$ #{PRODUCT} dkhamsing/open-source-ios-apps -mv threads=10 \n"\
      "$ #{PRODUCT} dkhamsing/open-source-ios-apps stars \n"\
      "\n#{em_logo} \n- Fetching GitHub repo information and creating pull"\
      " requests require credentials in .netrc \n"\
      '- More information: '\
      "#{PROJECT_URL.white.underline}"

      puts m
    end
  end # class
end
