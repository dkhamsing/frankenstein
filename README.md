# Frankenstein

`frankenstein` can correct [correct links](https://github.com/ReadmeCritic) in [GitHub](#github) READMEs :octocat:

[![Build Status](https://travis-ci.org/dkhamsing/frankenstein.svg)](https://travis-ci.org/dkhamsing/frankenstein)

![](http://i.giphy.com/2MMB4JT8lokbS.gif)

This project uses [`awesome_bot`](https://github.com/dkhamsing/awesome_bot) to validate links, it's very much a [work in progress](https://github.com/dkhamsing/frankenstein/pull/2) (the code is horrible)

See [ReadmeCritic/Run](https://github.com/ReadmeCritic/Run) to request a `frankenstein` run on a repo (you can also [opt out](https://github.com/ReadmeCritic/Disinterest) :no_good:)

Jump to
- [Installation](#installation)
- [Usage](#usage)
  - [GitHub](#github)
  - [Correct READMEs](#correct-readmes)
- [Examples](#examples)
- [Additional Tools](#additional-tools)
- [Credits](#credits)
- [Contact](#contact)
- [License](#license)

## Installation

```shell
git clone https://github.com/dkhamsing/frankenstein.git
cd frankenstein
rake install

# frankenstein is installed 😎
```

## Usage

```shell
frankenstein <url|file|github repo> [-mvz] [head] [repo] [threads=d] [silent]
```

Additional tools available: [`announce`](#announce),
[`comments`](#comments),
[`issues`](#issues),
[`mergeclose`](#mergeclose),
[`new`](#new),
[`review`](#review),
[`todo`](#todo)
and [`scan`](#scan).

## Examples

See some actual runs [here](https://gist.github.com/ReadmeCritic) 🏃

```shell
$ frankenstein README.md # file on disk
$ frankenstein https://fastlane.tools # URL

🏃  Processing links for https://fastlane.tools ...
🔎  Checking 50 links
✅  http://gradle.org/
✅  https://cocoapods.org
✅  https://github.com/fastlane/fastlane
# ...
📋  frankenstein results: 4 issues (8%)
   (4 of 50 links)
🔶  301 https://t.co/an02Vvi8Tl
# ...
🔶  4 redirects
https://t.co/an02Vvi8Tl redirects to
https://github.com/fastlane/snapshot
# ...
Wrote log to logs/1446869147-2015-11-06-fastlane.tools.frankenstein

🕐  Time elapsed: 17.51 seconds

🏃  No failures for https://fastlane.tools
```

```
✅ 200 ok
🔶 3xx redirect
🔴 4xx error
⚪ white list / other
```

```shell
$ frankenstein ccgus/fmdb # check URLs in a GitHub repo readme
$ frankenstein https://github.com/ccgus/fmdb

Finding default branch for ccgus/fmdb
Found: master for ccgus/fmdb — A Cocoa / Objective-C wrapper around SQLite — 8025⭐️  — last updated 1 day ago
🏃  Processing links for https://raw.githubusercontent.com/ccgus/fmdb/master/README.markdown ...
🔎  Checking 14 links
✅  http://www.sqlite.org/docs.html
✅  http://sqlite.org/
✅  http://www.sqlite.org/faq.html
⚪  301 http://groups.google.com/group/fmdb
# ...
```

```shell
$ frankenstein dkhamsing/frankenstein

Finding default branch for dkhamsing/frankenstein
Found: 1.0-wip for dkhamsing/frankenstein — Checks for live URLs and correct READMEs — 48⭐️  — last updated today
🏃  Processing links for https://raw.githubusercontent.com/dkhamsing/frankenstein/1.0-wip/README.md ...
🔎  Checking 56 links
✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
# ...
```

```shell
$ frankenstein dkhamsing/open-source-ios-apps -v # verbose output
$ frankenstein dkhamsing/open-source-ios-apps head # make head requests (faster), some pages block these though and get reported as errors 😕
$ frankenstein dkhamsing/open-source-ios-apps -mv head # combine flags and options (flags have to be ahead of options)
$ frankenstein dkhamsing/open-source-ios-apps threads=15 # use 15 parallel threads (the default is 10, use threads=0 to disable threading)
```

### GitHub

Integration with GitHub (repo information, pull request, gists) requires credentials set in [.netrc](http://octokit.github.io/octokit.rb/#Using_a__netrc_file).

`-z` `repo`

```shell
$ frankenstein dkhamsing/open-source-ios-apps repo # get GitHub info only and skip checking URLs
$ frankenstein dkhamsing/open-source-ios-apps -z # get GitHub info after checking URLs

# ...
🔎  Getting information for 239 GitHub repos
⭐️  143 artsy/Emergence 🔥  last updated 4 days ago
⭐️  19 neonichu/CoolSpot  last updated 5 months ago
⭐️  138 lazerwalker/cortado 🔥  last updated 3 months ago
⭐️  931 Dimillian/SwiftHN 🔥 🔥 🔥  last updated 5 months ago
⭐️  1947 austinzheng/swift-2048 🔥 🔥 🔥 🔥  last updated 13 days ago
⭐️  1482 ericjohnson/canabalt-ios 🔥 🔥 🔥 🔥  last updated 51 months ago
⭐️  264 jpsim/CardsAgainst 🔥 🔥  last updated 12 days ago
# ...
```

```
 100+ Stars: 🔥
 200+ Stars: 🔥🔥
 500+ Stars: 🔥🔥🔥
1000+ Stars: 🔥🔥🔥🔥
2000+ Stars: 🔥🔥🔥🔥🔥
```

`frankenstein` can create a gist of its output results and send a tweet out:

```shell
$ frankenstein johnno1962/GitDiff

Finding default branch for johnno1962/GitDiff
Found: master for johnno1962/GitDiff — Highlights deltas against git repo in Xcode — 645⭐️  — last updated 1 day ago
🏃  Processing links for https://raw.githubusercontent.com/johnno1962/GitDiff/master/README.md ...
🔎  Checking 4 links
#...
Next? (pull request | gist | tweet [-h] [message] | enter to end) t no failures @Injection4Xcode 🎉           
🏃 Creating a gist for 1446854221-2015-11-06-johnno1962-GitDiff.frankenstein
  Reading content
  Creating GitHub client
  Client creating gist
  🎉 gist created: https://gist.github.com/f24c57c9989f4c5e373d
  🐦 Tweet sent: https://twitter.com/ReadmeCritic/status/662781085479137280
```

Tweeting requires credentials in [.netrc](lib/frankenstein/twitter.rb) (also see [`announce`](#announce)).

### Correct READMEs

`frankenstein` can open a pull request to update HTTP redirects in a repo README (see also [ReadmeCritic/Run](https://github.com/ReadmeCritic/Run)).

```shell
$ frankenstein fastlane/sigh

Finding default branch for fastlane/sigh
Found: master for fastlane/sigh — Because you would rather spend your time building stuff than fighting provisioning — 864⭐️  — last updated 8 days ago
🏃  Processing links for https://raw.githubusercontent.com/fastlane/sigh/master/README.md ...
🔎  Checking 21 links
🔶  301 https://github.com/KrauseFx/fastlane
🔶  301 https://github.com/KrauseFx/deliver
#...
🔶  10 redirects
https://github.com/KrauseFx/fastlane redirects to
https://github.com/fastlane/fastlane
#...
Next? (pull request | white list w=<s1^s2..> | gist | tweet [-h] [message] | enter to end) p
Creating pull request on GitHub for fastlane/sigh ...
Pull request created: https://github.com/fastlane/sigh/pull/195
```

Example pull requests with `frankenstein`:

- https://github.com/fastlane/sigh/pull/195
- https://github.com/kylef/Commander/pull/14
- https://github.com/bbatsov/rubocop/pull/2387
- https://github.com/nwjs/nw.js/pull/3948
- https://github.com/NYTimes/objective-c-style-guide/pull/137
- https://github.com/airbnb/javascript/pull/564
- https://github.com/hangtwenty/dive-into-machine-learning/pull/14

### White list

Some URLs that are meant to be redirected (i.e. URL shortener, badge, authentication) have been [white listed](lib/frankenstein/constants.rb).

You an also white list items after a run or while using [`review`](#review) (option `w`).

```shell
$ frankenstein dkhamsing/forker

Finding default branch for dkhamsing/forker
Found: wip for dkhamsing/forker — Fork GitHub repos found on a page — 0⭐️  — last updated today
🏃  Processing links for https://raw.githubusercontent.com/dkhamsing/forker/wip/README.md ...
🔎  Checking 10 links
✅  https://avatars.githubusercontent.com/u/4372882?v=3
#...
🔶  3 redirects
http://gph.is/1768v38 -40 redirects to
http://giphy.com/gifs/loop-factory-how-its-made-n1JN4fSrXovJe
#...
🕐  Time elapsed: 2.56 seconds

🏃  No failures for dkhamsing/forker

Next? (pull request | white list w=<s1^s2..> | gist | tweet [-h] [message] | enter to end) w=gph
```

## Additional Tools

For more information, type `tool-name` without arguments.

```shell
$ review
review Facilitate creating pull requests to update redirects
Usage: review <file>
       review logs
       review logs all
       review logs done
       review logs <n> or
       review <n>
       review <n> done
```

### `announce`

`announce` can post a .frankenstein results log file to a gist and optionally tweet the gist link.

### `comments`

`comments` gather comments from merged pull requests.

### `issues`

`issues` lists open and merged GitHub issues.

### `mergeclose`

`mergeclose` checks the status of a pull request (if closed, it deletes the fork and sends a tweet out).

### `new`

`new` checks GitHub for new notifications and processes 'em.

### `review`

`review` processes logs before opening a pull request to update redirects.

### `scan`

`scan` runs `frankenstein` in batch (also works with `todo`).

### `todo`

`todo` manages a list of `frankenstein` runs to do.

## Credits

- `faraday`, `parallel`, `octokit` and [more](frankenstein.gemspec).
- [@eteubert](http://stackoverflow.com/questions/5532362/how-do-i-get-the-destination-url-of-a-shortened-url-using-ruby/20818142#20818142) and [@mgreensmith](http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/).
- [awesome-aws](https://github.com/donnemartin/awesome-aws) for that 🔥.
- [giphy](http://giphy.com/gifs/2MMB4JT8lokbS) for "it's alive" image.
- [@jasoncostello](https://octodex.github.com/inspectocat/) for inspectocat.

## Contact

- [github.com/dkhamsing](https://github.com/dkhamsing)
- [twitter.com/dkhamsing](https://twitter.com/dkhamsing)

## License

This project is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
