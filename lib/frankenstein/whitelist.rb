# White list
module Frankenstein
  REDIRECTED_WHITE_LIST =
  [
    'clojure.org/.*responseToken=',
    '://code.google.com/hosting/moved',
    'raw.githubusercontent.com',
    'Main_Page',
    '://nodejs.org/en/',
    'http://www.opentable.com/start/home',
    'https://www.paypal.com/home'
  ]

  URL_SHORTENER_WHITE_LIST =
  [
    '://aka.ms/',
    '://amzn.com/',
    '//amzn.to/',
    '//bit.ly/',
    '//bitly.com',
    '//cl.ly/',
    '://db.tt/',
    '://eepurl.com/',
    '://fb.me/',
    '://git.io/',
    '://goo.gl/',
    '//j.mp/',
    '//mzl.la/',
    '://t.co/',
    '://t.cn/',
    '://youtu.be/'
  ]

  REGEX_WHITE_LIST =
  [
    '://127',
    '//developer.apple.com/xcode/download',
    '//ci.appveyor.com/api',
    '://badge.fury.io/',
    '://bitbucket.org/repo/create',
    '://cocoapod-badges',
    '://coveralls.io/r/',
    '://coveralls.io/repos.*(pn|sv)g',
    '://discord.gg/',
    'facebook.com/sharer',
    'facebook.com/groups',
    '://fury-badge.herokuapp.com/.*png',
    '://shop.github.com$',
    '://enterprise.github.com/$',
    '://github.com/.*/blob/',
    '://github.com/.*/fork$',
    '://github.com/pulls',
    '://github.com/security',
    '://github.com/site',
    '://github.com/new',
    '://github.com/watching',
    '://github.com/.*/new$',
    '://github.com.*releases/new',
    '://github.com.*releases/download/',
    '://github.com.*releases/latest',
    '://github.com.*/archive/.*.(gz|zip)',
    '://github.com.*\.git$',
    '://github.com.*/tree/',
    '://github.com/.*/zipball/',
    '://github.com/.*/tarball/',
    '://github.com/.*/raw/',
    '://github.com/.*state=open$',
    '//github.com/.*contributors$',
    'github.io',
    '//gratipay.com/',
    '//heroku.com/deploy',
    '//meritbadge.herokuapp.com',
    'issuestats.com/',
    '://localhost',
    '://maven-badges.herokuapp.com/',
    '://ogp.me/ns',
    '://raw.github.com/',
    '://group.google.com',
    '://groups.google',
    '://i.creativecommons.org/.*png',
    '://instagram.com/',
    'paypal.com/cgi-bin/webscr',
    'plus.google.com/share',
    'readthedocs.org',
    'reddit.com/message/compose',
    '://secure.travis-ci.org/.*(pn|sv)g',
    'my.slack.com/services',
    'sourceforge.net/projects/.*/download$',
    '://stackoverflow.com/questions/ask?',
    '//swift.org',
    '//bugs.swift.org',
    '://twitter.com/home',
    '://travis-ci.org/.*png',
    '://travis-ci.org/.*svg',
    '://weibo.com/'
  ]
end
