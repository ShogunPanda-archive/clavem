# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require File.expand_path('../lib/clavem/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = "clavem"
  gem.version = Clavem::Version::STRING
  gem.homepage = "http://sw.cow.tc/clavem"
  gem.summary = "A local callback server for oAuth web-flow."
  gem.description = "A local callback server for oAuth web-flow."
  gem.rubyforge_project = "clavem"

  gem.authors = ["Shogun"]
  gem.email = ["shogun@cowtech.it"]

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 1.9.3"

  gem.add_dependency("bovem", "~> 3.0.2")
  gem.add_dependency("eventmachine", "~> 1.0.3")
  gem.add_dependency("eventmachine_httpserver", "~> 0.2.1")
end
