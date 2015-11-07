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
frankenstein <url|file|github repo> [-fmzv] [head] [repo] [threads=d] [wl=s]
```

### Examples

See some actual example runs [here](https://gist.github.com/frankenbot) 🏃

```shell
$ frankenstein README.md # file on disk
$ frankenstein https://fastlane.tools # URL

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
Wrote log to logs/1446751796-2015-11-05-https---fastlane.tools.frankenstein

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
$ frankenstein dkhamsing/open-source-ios-apps head # head requests only (use this option to speed up frankenstein, some URLs may be misreported as errors using this option 😕)
$ frankenstein dkhamsing/open-source-ios-apps -fv head # combine flags and options (flags have to be ahead of options)
$ frankenstein dkhamsing/open-source-ios-apps threads=10 # use 10 parallel threads (the default is 5, use threads=0 to disable threading)
```

#### GitHub

Getting repo information / creating a pull request for redirects require a GitHub account with username and passwords set in a [.netrc file](http://octokit.github.io/octokit.rb/#Using_a__netrc_file).

`-z` `repo`

```shell
$ frankenstein dkhamsing/open-source-ios-apps repo # get GitHub info only and skip checking URLs
$ frankenstein dkhamsing/open-source-ios-apps -z # get GitHub info after checking URLs

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

`frankenstein` can also open a pull request to update redirects:

```shell
$ frankenstein fastlane/sigh

🏃  Processing links for https://raw.githubusercontent.com/fastlane/sigh/master/README.md ...
🔎  Checking 23 links
1/23 	 🔶  301 https://github.com/KrauseFx/fastlane
2/23 	 🔶  301 https://github.com/KrauseFx/deliver
#...
🔶  10 redirects
https://github.com/KrauseFx/fastlane redirects to
https://github.com/fastlane/fastlane
#...
Next? (pull | gist | tweet [-h] [message] | enter to end) pull
Creating pull request on GitHub for fastlane/sigh ...
Pull request created: https://github.com/fastlane/sigh/pull/195
```

Example pull requests by `frankenstein`:

- https://github.com/fastlane/sigh/pull/195
- https://github.com/kylef/Commander/pull/14
- https://github.com/bbatsov/rubocop/pull/2387
- https://github.com/nwjs/nw.js/pull/3948
- https://github.com/NYTimes/objective-c-style-guide/pull/137
- https://github.com/airbnb/javascript/pull/564
- https://github.com/hangtwenty/dive-into-machine-learning/pull/14
- more https://twitter.com/frankenb0t

`frankenstein` can create a gist of the results and send a tweet out:

```shell
$ frankenstein johnno1962/GitDiff

Finding default branch for johnno1962/GitDiff
Found: master for johnno1962/GitDiff — Highlights deltas against git repo in Xcode — 645⭐️  — last updated 1 day ago
🏃  Processing links for https://raw.githubusercontent.com/johnno1962/GitDiff/master/README.md ...
🔎  Checking 4 links
#...
Next? (pull | gist | tweet [-h] [message] | enter to end) tweet no failures @Injection4Xcode 🎉           
🏃 Creating a gist for 1446854221-2015-11-06-johnno1962-GitDiff.frankenstein
  Reading content
  Creating GitHub client
  Client creating gist
  🎉 gist created: https://gist.github.com/f24c57c9989f4c5e373d
  🐦 Tweet sent: https://twitter.com/frankenb0t/status/662781085479137280
```

#### White list

Some URLs that are meant to be redirected (i.e. URL shortener, badge, authentication) have been [white listed](lib/frankenstein/constants.rb).

```shell
$ frankenstein docker/docker wl=tryit^openvz # additional items to white list, separated by ^
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

- `faraday`, `parallel`, `octokit` and [more](frankenstein.gemspec).
- [@eteubert](http://stackoverflow.com/questions/5532362/how-do-i-get-the-destination-url-of-a-shortened-url-using-ruby/20818142#20818142) and [@mgreensmith](http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/).
- [awesome-aws](https://github.com/donnemartin/awesome-aws) for that 🔥.
- [giphy](http://giphy.com/gifs/2MMB4JT8lokbS) for "it's alive" image.

## Contact

- [github.com/dkhamsing](https://github.com/dkhamsing)
- [twitter.com/dkhamsing](https://twitter.com/dkhamsing)

## License

This project is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
