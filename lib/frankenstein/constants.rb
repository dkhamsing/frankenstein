# Constants
module Frankenstein
  ARGV1_FILE = 'file'
  ARGV1_GITHUB_REPO = 'github repo'
  ARGV1_URL = 'url'

  CONTROLLED_ERROR = 'https://github.com/dkhamsing/controlled/error'

  DEFAULT_NUMBER_OF_ITEMS_PER_ROWS = 10
  DEFAULT_NUMBER_OF_THREADS = 5

  FILE_LOG = 'logs/franken_log'
  FILE_TEMP = 'logs/franken_temp'

  FLAG_FAIL = 'f'
  FLAG_GITHUB_STARS = 'c'
  FLAG_MINIMIZE_OUTPUT = 'm'
  FLAG_VERBOSE = 'v'

  GITHUB_API_BASE = 'https://api.github.com/'

  NETRC_GITHUB_MACHINE = 'api.github.com'

  OPTION_LAST_PUSH = 'push'
  OPTION_LOG = 'log'
  OPTION_PULL_REQUEST = 'pull'
  OPTION_ROW = 'row'
  OPTION_STARS = 'stars'
  OPTION_THREADS = 'threads'

  PROJECT_URL = 'https://github.com/dkhamsing/frankenstein'

  PULL_REQUEST_TITLE = 'Update redirects'
  PULL_REQUEST_DESCRIPTION = "Created with #{PROJECT_URL}"

  README_VARIATIONS = [
    'README.md',
    'Readme.md',
    'readme.md',
    'README.markdown',
    'Readme.markdown',
    'index.html'
  ]

  SEPARATOR = '='

  WHITE_LIST_REGEXP = [
    '//coveralls.io/repos.*svg',
    '//github.com.*issues/new',
    '//github.com.*ch/new',
    '//github.com.*\.git$',
    '//i.creativecommons.org/.*png'
  ]
end
