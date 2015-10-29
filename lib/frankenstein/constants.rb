module Frankenstein
  ARGV1_FILE = 'file'
  ARGV1_GITHUB_REPO = 'github repo'
  ARGV1_URL = 'url'

  CONTROLLED_ERROR = "https://github.com/dkhamsing/controlled/error"

  FILE_LOG = "franken_log"
  FILE_TEMP = "franken_temp"

  FLAG_FAIL = "f"
  FLAG_GITHUB_STARS = "c"
  FLAG_MINIMIZE_OUTPUT = "m"
  FLAG_VERBOSE = "v"

  GITHUB_API_BASE = "https://api.github.com/"

  NETRC_GITHUB_MACHINE = "api.github.com"

  OPTION_LOG = "log"
  OPTION_PULL_REQUEST = "pull"
  OPTION_ROW = "row"
  OPTION_STARS = "stars"
  OPTION_THREADS = "threads"

  PULL_REQUEST_TITLE = "Update redirects"
  PULL_REQUEST_DESCRIPTION = "Created with https://github.com/dkhamsing/frankenstein"

  README_VARIATIONS = [
    "README.md",
    "Readme.md",
    "readme.md",
    "README.markdown",
    "Readme.markdown",
    "index.html"
  ]

  SEPARATOR = "="

  WHITE_LIST_REGEXP = [
    "//coveralls.io/repos.*svg",
    "//github.com.*issues/new",
    "//github.com.*ch/new",
    "//github.com.*\.git$",
    "//i.creativecommons.org/.*png",
  ]
end
