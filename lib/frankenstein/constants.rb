# Constants
module Frankenstein
  ARGV1_FILE = 'file'
  ARGV1_GITHUB_REPO = 'github repo'
  ARGV1_URL = 'url'

  CONTROLLED_ERROR = 'https://github.com/dkhamsing/controlled/error'

  DEFAULT_NUMBER_OF_THREADS = 5

  FILE_LOG_DIRECTORY = 'logs'

  FILE_COPY = 'copy'
  FILE_REPO = "#{FILE_LOG_DIRECTORY}/franken_repos.json"
  FILE_REDIRECTS = 'redirects'
  FILE_UPDATED = 'updated'

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

  PULL_REQUEST_COMMIT_MESSAGE = 'Readme: Update redirects'
  PULL_REQUEST_TITLE = 'Update Readme'
  PULL_REQUEST_DESCRIPTION = "Created with #{PROJECT_URL}"

  README_VARIATIONS = [
    'README.md',
    'Readme.md',
    'readme.md',
    'README.markdown',
    'Readme.markdown',
    'README',
    'README.rst',
    'README.asciidoc',
    'README.rdoc',
    'index.html',
    'readme.creole'
  ]

  SEPARATOR = '='

  WHITE_LIST_STATUS = -1

  WHITE_LIST_REGEXP = [
    '://127',
    '://amzn.com/',
    '://badge.fury.io/',
    '//bit.ly/',
    '//cl.ly/',
    '://coveralls.io/r/',
    '://coveralls.io/repos.*(pn|sv)g',
    '://discord.gg/',
    '://eepurl.com/',
    'facebook.com/sharer',
    '://fb.me/',
    '://fury-badge.herokuapp.com/.*png',
    '://shop.github.com$',
    '://enterprise.github.com/$',
    '://github.com/security',
    '://github.com/site',
    '://github.com/new',
    '://github.com/.*/new$',
    '://github.com.*releases/new',
    '://github.com.*releases/download/',
    '://github.com.*releases/latest',
    '://github.com.*/archive/.*.(gz|zip)',
    '://github.com.*\.git$',
    '://github.com.*/tree/',
    '://github.com/.*/zipball/',
    '://localhost',
    '://maven-badges.herokuapp.com/',
    '://ogp.me/ns',
    '://raw.github.com/',
    '://groups.google.com',
    '://i.creativecommons.org/.*png',
    '://instagram.com/',
    'plus.google.com/share',
    'reddit.com/message/compose',
    '://secure.travis-ci.org/.*(pn|sv)g',
    '://stackoverflow.com/questions/ask?',
    '://t.co/',
    '://twitter.com/home',
    '://travis-ci.org/.*png',
    '://travis-ci.org/.*svg',
    '://youtu.be/'
  ]
end
