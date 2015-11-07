# Usage
module Frankenstein
  require 'colored'

  class << self
    def all_argv1
      "#{ARGV1_URL.magenta}|#{ARGV1_FILE.magenta}|"\
        "#{ARGV1_GITHUB_REPO.magenta}"
    end

    def usage
      m = "#{em_logo} #{'Check for live URLS on a page'.white} \n" \
          "#{PRODUCT.green} <#{all_argv1}> "\
      "[-#{cli_all_flags.join.blue}] "\
      "[#{OPTION_HEAD.blue}] "\
      "[#{OPTION_STARS.blue}] "\
      "[#{OPTION_THREADS.blue}=d] "\
      "[#{OPTION_WHITE_LIST.blue}=s1^s2..] "\
      "[#{OPTION_SKIP.blue}] "\
      "\n"\
      "   #{ARGV1_URL.magenta} \t\t URL for the page \n"\
      "   #{ARGV1_GITHUB_REPO.magenta} \t GitHub repository \n"\
      "   #{ARGV1_FILE.magenta} \t File on disk \n\n"\
      "   #{FLAG_FAIL.blue} \t\t #{FLAG_FAIL_USAGE} \n"\
      "   #{FLAG_MINIMIZE_OUTPUT.blue} \t\t #{FLAG_MINIMIZE_USAGE} \n"\
      "   #{FLAG_VERBOSE.blue} \t\t #{FLAG_VERBOSE_USAGE} \n"\
      "   #{FLAG_GITHUB_STARS.blue} \t\t #{FLAG_GITHUB_USAGE} \n"\
      "\n   #{OPTION_HEAD.blue} \t Check URLs with head requests 🚀 \n"\
      "   #{OPTION_STARS.blue} \t Get GitHub repo info only \n"\
      "   #{OPTION_THREADS.blue} \t Number of parallel threads "\
      "(#{DEFAULT_NUMBER_OF_THREADS} is the default) \n"\
      "   #{OPTION_WHITE_LIST.blue} \t\t ^ separated items to white list "\
      "\n"\
      "   #{OPTION_SKIP.blue} \t Skip prompt at end of the run \n"\
      "\n#{em_logo} #{'Examples'.white} \n"\
      "$ #{PRODUCT} https://fastlane.tools \n"\
      "$ #{PRODUCT} README.md \n"\
      "$ #{PRODUCT} dkhamsing/open-source-ios-apps -mv threads=10 \n"\
      "$ #{PRODUCT} dkhamsing/open-source-ios-apps stars \n"\
      "\n#{em_logo} \n- Fetching GitHub repo information "\
      "require credentials in .netrc \n"\
      '- More information: '\
      "#{PROJECT_URL.white.underline}"

      puts m
    end
  end # class
end
