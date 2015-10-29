require "frankenstein/constants"
require "frankenstein/emoji"

module Frankenstein
  require 'colored'

  class << self
    def usage
      puts "#{logo} Check for live URLS on a page".white
      puts "#{"frankenstein".green} <#{"url|github repo|file".magenta}> "\
      "[#{"-fgmv".blue}] "\
      "[#{OPTION_LOG.blue}] "\
      "[#{OPTION_PULL_REQUEST.blue}] "\
      "[#{OPTION_ROW.blue}=d] "\
      "[#{OPTION_STARS.blue}] "\
      "[#{OPTION_THREADS.blue}=d] "
      puts "   #{"url".magenta} \t\t URL for the page"
      puts "   #{"github repo".magenta} \t GitHub repository"
      puts "   #{"file".magenta} \t File on disk"

      puts "\n   #{FLAG_FAIL.blue} \t\t Add a controlled failure"
      puts "   #{FLAG_GITHUB_STARS.blue} \t\t Fetch GitHub repo star count"
      puts "   #{FLAG_MINIMIZE_OUTPUT.blue} \t\t Minimized result output (see row option below)"
      puts "   #{FLAG_VERBOSE.blue} \t\t Verbose output"

      puts "\n   #{OPTION_LOG.blue} \t\t Write log to file"
      puts "   #{OPTION_PULL_REQUEST.blue} \t Create a pull request with updated redirects"
      puts "   #{OPTION_ROW.blue} \t\t Number of items per row (minimized output, 10 is the default, only works with threads=0)"
      puts "   #{OPTION_STARS.blue} \t Fetch GitHub repo star count only"
      puts "   #{OPTION_THREADS.blue} \t Number of parallel threads (5 is the default)"

      puts "\n#{logo} Examples".white
      puts "$ frankenstein https://fastlane.tools"
      puts "$ frankenstein README.md"
      puts "$ frankenstein dkhamsing/open-source-ios-apps -mv threads=10"
      puts "$ frankenstein dkhamsing/open-source-ios-apps stars"

      puts "\n#{logo} \n- Fetching GitHub repo star count and creating pull requests requires credentials in .netrc"
      puts "- More information: #{"https://github.com/dkhamsing/frankenstein".white.underline}"
    end
  end #class
end
