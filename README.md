![](assets/its-alive.gif)

# Frankenstein

`frankenstein` checks for live URLs on a page and works with [GitHub](#github) & [Travis](#travis).

[![Build Status](https://travis-ci.org/dkhamsing/frankenstein.svg)](https://travis-ci.org/dkhamsing/frankenstein)

![](assets/demo.gif)

This is still a [work in progress](https://github.com/dkhamsing/frankenstein/pull/2) :runner: :octocat: :construction_worker:

## Installation

```shell
git clone https://github.com/dkhamsing/frankenstein.git
cd frankenstein
bundle install

# you can now run frankenstein from bin/ 😎
```

## Usage

```shell
frankenstein <url|file|github repo> [-fmzv] [head] [log] [pull] [repo] [threads=d] [wl=s]
```

### Examples

```shell
$ frankenstein README.md # file on disk
$ frankenstein https://fastlane.tools #url

🏃  Processing links on https://fastlane.tools ...
🔎  Checking 50 links
1/50 	 ✅   https://github.com/krausefx/fastlane
2/50 	 ✅   https://github.com/KrauseFx/fastlane
# ...
📋  frankenstein results: 4 issues (8%)
   (4 of 50 links)
🔶  301 https://t.co/an02Vvi8Tl
# ...
🔶  4 redirects
https://t.co/an02Vvi8Tl redirects to
https://github.com/fastlane/snapshot
# ...
🕐  Time elapsed: 17.51 seconds

🏃  No failures for https://fastlane.tools
```

```
✅ 200 ok
🔶 3xx redirect
🔴 4xx error
⚪ other
```

```shell
$ frankenstein dkhamsing/open-source-ios-apps # GitHub repo
$ frankenstein dkhamsing/open-source-ios-apps -f # add a controlled failure

🏃  Processing links on https://raw.githubusercontent.com/dkhamsing/open-source-ios-apps/master/README.md ...
🔎  Checking 351 links
1/351 	 🔴 404 https://github.com/dkhamsing/controlled/error # controlled failure
2/351 	 ✅   https://github.com/dkhamsing/open-source-ios-apps/issues
3/351 	 ✅   https://github.com/dkhamsing/open-source-ios-apps/pulls
# ...
```

```shell
$ frankenstein matteocrippa/awesome-swift -m # minimized result output

🏃  Processing links on https://raw.githubusercontent.com/matteocrippa/awesome-swift/master/README.md ...
🔎  Checking 456 links:
✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
# ...
```

```shell
$ frankenstein dkhamsing/open-source-ios-apps -v # verbose output
$ frankenstein dkhamsing/open-source-ios-apps head # head requests only (use this option to speed up frankenstein, some urls may be misreported as errors using this option 😕)
$ frankenstein dkhamsing/open-source-ios-apps log # write log to a file named franken_log
$ frankenstein dkhamsing/open-source-ios-apps -fv log # combine flags and options (flags have to be ahead of options)
$ frankenstein dkhamsing/open-source-ios-apps threads=10 # use 10 parallel threads (the default is 5, use threads=0 to disable threading)
```

#### GitHub

Getting repo information / creating a pull request for redirects require a GitHub account with username and passwords set in a [.netrc file](http://octokit.github.io/octokit.rb/#Using_a__netrc_file).

`-z` `repo`

```shell
$ frankenstein dkhamsing/open-source-ios-apps repo # get GitHub info only and skip checking urls
$ frankenstein dkhamsing/open-source-ios-apps -z # get GitHub info after checking urls

🏃  Processing links on https://raw.githubusercontent.com/dkhamsing/open-source-ios-apps/master/README.md ...
🔎  Checking 350 links
1/350 	 ✅   https://github.com/dkhamsing/open-source-ios-apps/issues
2/350 	 ✅   https://github.com/dkhamsing/open-source-ios-apps/pulls
# ...
🔎  Getting information for 228 GitHub repos
⭐️  311 kenshin03/Cherry 🔥 🔥  last updated 4 months ago
⭐️  18 neonichu/CoolSpot  last updated 5 months ago
⭐️  2312 pcqpcq/open-source-android-apps 🔥 🔥 🔥 🔥 🔥  last updated 4 days ago
# ...
```

```
 100+ Stars: 🔥
 200+ Stars: 🔥🔥
 500+ Stars: 🔥🔥🔥
1000+ Stars: 🔥🔥🔥🔥
2000+ Stars: 🔥🔥🔥🔥🔥
```

`pull`

```shell
$ frankenstein fastlane/sigh pull # create a pull request replacing redirects

🏃  Processing links for https://raw.githubusercontent.com/fastlane/sigh/master/README.md ...
🔎  Checking 23 links
1/23 	 🔶  301 https://github.com/KrauseFx/fastlane
2/23 	 🔶  301 https://github.com/KrauseFx/deliver
#...
🔶  10 redirects
https://github.com/KrauseFx/fastlane redirects to
https://github.com/fastlane/fastlane
#...
Would you like to open a pull request? (y/n) y
Creating pull request on GitHub for fastlane/sigh ...
Pull request created: https://github.com/fastlane/sigh/pull/195

🕐  Time elapsed: 12.3 seconds

🏃  No failures for fastlane/sigh
```

Example uses of `frankenstein` with `pull` option:

- https://github.com/fastlane/sigh/pull/195
- https://github.com/fastlane/frameit/pull/65
- https://github.com/piemonte/PBJVision/pull/293
- https://github.com/kylef/Commander/pull/14
- https://github.com/bbatsov/rubocop/pull/2387

#### White list

Some URLs that are meant to be redirected (i.e. badge, authentication) have been [white listed](lib/frankenstein/constants.rb).

```shell
$ frankenstein docker/docker wl=tryit # additional item to white list
```

### Travis

- You can use `frankenstein` with [Travis](https://travis-ci.org/) to validate commits on GitHub.
- Examples with [dkhamsing/open-source-ios-apps](https://github.com/dkhamsing/open-source-ios-apps):
  - https://github.com/dkhamsing/open-source-ios-apps/pull/139
  - https://travis-ci.org/dkhamsing/open-source-ios-apps/builds/87775142
  - https://travis-ci.org/dkhamsing/open-source-ios-apps/builds/87774588

`.travis.yml` file

```
language: ruby
rvm:
  - 2.2
before_script:
  - wget https://codeload.github.com/dkhamsing/frankenstein/tar.gz/1.0-wip -O /tmp/frankenstein.tar.gz
  - tar -xvf /tmp/frankenstein.tar.gz
  - export PATH=$PATH:$PWD/frankenstein-1.0-wip/bin/
  - cd frankenstein-1.0-wip
  - bundle install
script:  
  - frankenstein ../README.md
```

## Credits

- `faraday`, `parallel`, `octokit` and [more](lib/frankenstein.rb).
- [@eteubert](http://stackoverflow.com/questions/5532362/how-do-i-get-the-destination-url-of-a-shortened-url-using-ruby/20818142#20818142) and [@mgreensmith](http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/).
- [awesome-aws](https://github.com/donnemartin/awesome-aws) for that 🔥.
- [giphy](http://giphy.com/gifs/2MMB4JT8lokbS) for "it's alive" image.

## Contact

- [github.com/dkhamsing](https://github.com/dkhamsing)
- [twitter.com/dkhamsing](https://twitter.com/dkhamsing)

## License

This project is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
