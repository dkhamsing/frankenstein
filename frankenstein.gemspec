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

  spec.files = Dir["lib/**/*"] + %w( bin/frankenstein README.md )
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.require_paths = ['lib']

  # dependencies
  spec.add_dependency 'colored', '~> 1.2'
  spec.add_dependency 'faraday', '~> 0.9.2'
  spec.add_dependency 'faraday_middleware', '~> 0.10.0'
  spec.add_dependency 'json', '~> 1.8.3'
  spec.add_dependency 'parallel', '~> 1.6.1'

  # github
  spec.add_dependency 'octokit', '~> 3.4.2'
  spec.add_dependency 'netrc', '~> 0.7.8'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'guard-rubocop', '~> 1.2.0'
end
