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

  spec.files         = Dir['lib/**/*'] + %w(bin/frankenstein README.md)
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.require_paths = ['lib']

  # dependencies
  spec.add_dependency 'awesome_bot', '~> 0.1'
  spec.add_dependency 'colored', '~> 1.2'
  spec.add_dependency 'faraday', '~> 0.9.2'
  spec.add_dependency 'faraday_middleware', '~> 0.10.0'
  spec.add_dependency 'json', '~> 1.8.3'
  spec.add_dependency 'parallel', '~> 1.6.1'
  spec.add_dependency 'differ', '~> 0.1.2'

  spec.add_dependency 'octokit', '~> 4.2.0' # github
  spec.add_dependency 'netrc', '~> 0.11.0' # credentials
  spec.add_dependency 'twitter', '~> 5.15.0' # tweets
  spec.add_dependency 'github-trending', '~> 0.2.3' # scan

  spec.add_development_dependency 'bundler', '~> 1.7' # travis needs this at 1.7
  spec.add_development_dependency 'rake', '~> 10.4.2'
  spec.add_development_dependency 'guard-rubocop', '~> 1.2.0'
end
