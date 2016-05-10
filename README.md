# Frankenstein

`frankenstein` checks for live URLs in a file, it can [update links based on HTTP redirects](#correct-github-readme-redirects) in a README :octocat:

![](http://i.giphy.com/2MMB4JT8lokbS.gif)

This project uses [`awesome_bot`](https://github.com/dkhamsing/awesome_bot) to validate links.

[![Build Status](https://travis-ci.org/dkhamsing/frankenstein.svg)](https://travis-ci.org/dkhamsing/frankenstein)

## Installation

```shell
git clone https://github.com/dkhamsing/frankenstein.git
cd frankenstein
rake install
```

## Usage

```shell
$ frankenstein https://fastlane.tools # URL
$ frankenstein README.md # Path to file
$ frankenstein ccgus/fmdb # GitHub repo README, https://github.com/ccgus/fmdb works too

Found: master for ccgus/fmdb — A Cocoa / Objective-C wrapper around SQLite — 8935⭐️  — last updated today
🏃  Processing links for ccgus/fmdb ...
🔎  Checking 18 links
✅  https://www.zetetic.net/sqlcipher/
✅  http://sqlite.org/
✅  https://cocoapods.org/
✅  https://github.com/marcoarment/FCModel
✅  https://github.com/layerhq/FMDBMigrationManager
#...
🕐  Time elapsed: 4.07 seconds

🏃  No failures for ccgus/fmdb
```

```
✅ 200 ok
🔶 3xx redirect
🔴 4xx error
⚪ white list / other
```

### Correct GitHub README Redirects

`frankenstein` can open a pull request to update README links based on HTTP redirects (this requires credentials set in [.netrc](http://octokit.github.io/octokit.rb/#Using_a__netrc_file)).

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

### White List

- URLs that are meant to be redirected (i.e. URL shortener, badge, authentication) are [white listed](lib/frankenstein/whitelist.rb) and not corrected.

- You can also white list links at the end of a run with option `w`.

```shell
$ frankenstein dkhamsing/forker

Finding default branch for dkhamsing/forker
Found: wip for dkhamsing/forker — Fork GitHub repos found on a page — 0⭐️  — last updated today
🏃  Processing links for dkhamsing/forker ...
🔎  Checking 10 links
✅  https://github.com/opensourceios
#...
🔶  1 redirect
http://gph.is/1768v38 redirects to
http://giphy.com/gifs/loop-factory-how-its-made-n1JN4fSrXovJe
#...
🕐  Time elapsed: 2.56 seconds

🏃  No failures for dkhamsing/forker

Next? (pull request | white list w=<s1^s2..> | gist | tweet [-h] [message] | enter to end) w=gph
#...
```

## Contact

- [github.com/dkhamsing](https://github.com/dkhamsing)
- [twitter.com/dkhamsing](https://twitter.com/dkhamsing)

## License

This project is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
