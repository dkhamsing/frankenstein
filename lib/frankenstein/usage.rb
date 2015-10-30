require 'frankenstein/constants'
require 'frankenstein/emoji'

# Usage
module Frankenstein
  require 'colored'

  class << self
    def usage
      all_flags = FLAG_GITHUB_STARS.yellow + FLAG_FAIL +
                  FLAG_MINIMIZE_OUTPUT + FLAG_VERBOSE
      all_argv1 = "#{ARGV1_URL.magenta}|#{ARGV1_FILE.magenta}|"\
                  "#{ARGV1_GITHUB_REPO.magenta}"

      m = "#{logo} #{'Check for live URLS on a page'.white} \n" \
          "#{'frankenstein'.green} <#{all_argv1}> "\
      "[-#{all_flags.blue}] "\
      "[#{OPTION_LOG.blue}] "\
      "[#{OPTION_PULL_REQUEST.blue}] "\
      "[#{OPTION_ROW.blue}=d] "\
      "[#{OPTION_THREADS.blue}=d] "\
      "[#{OPTION_STARS.yellow}] "\
      "\n"\
      "   #{ARGV1_URL.magenta} \t\t URL for the page \n"\
      "   #{ARGV1_GITHUB_REPO.magenta} \t GitHub repository \n"\
      "   #{ARGV1_FILE.magenta} \t File on disk \n\n"\
      "   #{FLAG_GITHUB_STARS.yellow} \t\t Get GitHub repo info \n"\
      "   #{FLAG_FAIL.blue} \t\t Add a controlled failure \n"\
      "   #{FLAG_MINIMIZE_OUTPUT.blue} \t\t Minimized result output "\
      "(see row option below) \n"\
      "   #{FLAG_VERBOSE.blue} \t\t Verbose output \n"\
      "\n   #{OPTION_LOG.blue} \t\t Write log to file \n"\
      "   #{OPTION_PULL_REQUEST.blue} \t Create a pull request with updated "\
      "redirects \n"\
      "   #{OPTION_ROW.blue} \t\t Number of items per row (minimized output, "\
      "#{DEFAULT_NUMBER_OF_ITEMS_PER_ROWS} is the default, only works "\
      "with threads=0) \n"\
      "   #{OPTION_THREADS.blue} \t Number of parallel threads "\
      "(#{DEFAULT_NUMBER_OF_THREADS} is the default) \n"\
      "\n"\
      "   #{OPTION_STARS.yellow} \t Get GitHub repo info only \n"\
      "\n#{logo} #{'Examples'.white} \n"\
      "$ frankenstein https://fastlane.tools \n"\
      "$ frankenstein README.md \n"\
      "$ frankenstein dkhamsing/open-source-ios-apps -mv threads=10 \n"\
      "$ frankenstein dkhamsing/open-source-ios-apps stars \n"\
      "\n#{logo} \n- Fetching GitHub repo information and creating pull"\
      " requests require credentials in .netrc \n"\
      '- More information: '\
      "#{'https://github.com/dkhamsing/frankenstein'.white.underline}"

      puts m
    end
  end # class
end
