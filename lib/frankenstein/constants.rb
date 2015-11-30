# Constants
module Frankenstein
  require 'frankenstein/readmes'
  require 'frankenstein/whitelist'

  ARGV1_FILE = 'file'
  ARGV1_GITHUB_REPO = 'github repo'
  ARGV1_URL = 'url'

  CONTROLLED_ERROR = 'https://github.com/dkhamsing/controlled/error'

  DEFAULT_NUMBER_OF_THREADS = 10

  FILE_LOG_DIRECTORY = 'logs'

  FILE_COPY = 'copy'
  FILE_REPO = "#{FILE_LOG_DIRECTORY}/franken_repos.json"
  FILE_REDIRECTS = 'redirects'
  FILE_TODO = "#{FILE_LOG_DIRECTORY}/franken_todo.json"
  FILE_UPDATED = 'updated'
  FILE_VISITS = "#{FILE_LOG_DIRECTORY}/franken_visits.json"

  FLAG_FAIL = 'f'
  FLAG_GITHUB_STARS = 'z'
  FLAG_MINIMIZE_OUTPUT = 'm'
  FLAG_VERBOSE = 'v'

  FLAG_FAIL_USAGE = 'Add a controlled failure'
  FLAG_GITHUB_USAGE = 'Get GitHub repo info'
  FLAG_MINIMIZE_USAGE = 'Minimized result output'
  FLAG_VERBOSE_USAGE = 'Verbose output'

  OPTION_HEAD = 'head'
  OPTION_SKIP = 'no-prompt'
  OPTION_STARS = 'repo'
  OPTION_THREADS = 'threads'
  OPTION_WHITE_LIST = 'wl'

  PRODUCT = 'frankenstein'

  PROJECT_URL = 'https://github.com/dkhamsing/frankenstein'

  PULL_REQUEST_COMMIT_MESSAGE = 'Update README URLs based on HTTP redirects'
  PULL_REQUEST_TITLE = PULL_REQUEST_COMMIT_MESSAGE
  PULL_REQUEST_DESCRIPTION = "Created with #{PROJECT_URL}"

  SEPARATOR = '='

  WHITE_LIST_STATUS = -1
end
