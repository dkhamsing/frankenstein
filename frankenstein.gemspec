# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'frankenstein/version'
require 'frankenstein/constants'

Gem::Specification.new do |spec|
  spec.name          = Frankenstein::PRODUCT
  spec.version       = Frankenstein::VERSION
  spec.authors       = ['dkhamsing']
  spec.email         = ['dkhamsing8@gmail.com']

  spec.summary       = Frankenstein::SUMMARY
  spec.description   = Frankenstein::DESCRIPTION
  spec.homepage      = Frankenstein::PROJECT_URL
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = [spec.name]
  spec.bindir        = 'bin'
  spec.require_paths = ['lib']

  # dependencies
  spec.add_dependency 'awesome_bot', '~> 1.8.4'         # validate links
  spec.add_dependency 'colored', '~> 1.2'               # output
  spec.add_dependency 'differ', '~> 0.1.2'              # string diff

  spec.add_dependency 'github-readme', '~> 0.1.0.pre' # github
  spec.add_dependency 'netrc', '~> 0.11.0'            # credentials
  spec.add_dependency 'twitter', '~> 5.16'            # tweets
  spec.add_dependency 'github-trending', '~> 0.2.3'   # scan
end
