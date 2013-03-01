# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
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
  gem.email = ["shogun_panda@me.com"]

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 1.9.3"

  gem.add_dependency("mamertes", "~> 2.1.0")
  gem.add_dependency("webrick", "~> 1.3.1")
end
