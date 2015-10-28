module Frankenstein
  CONTROLLED_ERROR = "https://github.com/dkhamsing/controlled/error"

  FILE_LOG = "franken_log"
  FILE_TEMP = "franken_temp"

  FLAG_FAIL = "f"
  FLAG_GITHUB_STARS = "g"
  FLAG_MINIMIZE_OUTPUT = "m"
  FLAG_VERBOSE = "v"

  NETRC_GITHUB_MACHINE = "api.github.com"

  OPTION_LOG = "log"
  OPTION_PULL_REQUEST = "pull"
  OPTION_ROW = "row"
  OPTION_STARS = "stars"
  OPTION_THREADS = "threads"

  README_VARIATIONS = [
    "README.md",
    "Readme.md",
    "readme.md",
    "README.markdown"
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
