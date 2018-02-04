# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

require File.expand_path("../lib/clavem/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name = "clavem"
  gem.version = Clavem::Version::STRING
  gem.homepage = "http://sw.cowtech.it/clavem"
  gem.summary = "A local callback server for oAuth web-flow."
  gem.description = "A local callback server for oAuth web-flow."
  gem.rubyforge_project = "clavem"

  gem.authors = ["Shogun"]
  gem.email = ["shogun@cowtech.it"]
  gem.license = "MIT"

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.3.0"

  gem.add_dependency("bovem", "~> 4.0")
  gem.add_dependency("addressable", "~> 2.3")
end
