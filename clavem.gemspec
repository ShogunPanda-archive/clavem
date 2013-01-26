# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require File.expand_path('../lib/clavem/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = "clavem"
  gem.version = Clavem::Version::STRING
  gem.homepage = "http://github.com/ShogunPanda/clavem"
  gem.summary = "A local callback server for oAuth web-flow."
  gem.description = "A local callback server for oAuth web-flow."
  gem.rubyforge_project = "clavem"

  gem.authors = ["Shogun"]
  gem.email = ["shogun_panda@me.com"]

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 1.9.2"

  gem.add_dependency("r18n-desktop", "~> 1.1.3")
  gem.add_dependency("lazier", "~> 1.0.7")
  gem.add_dependency("mamertes", "~> 1.2.0")
  gem.add_dependency("webrick", "~> 1.3.1")

  gem.add_development_dependency("rspec", "~> 2.12.0")
  gem.add_development_dependency("rake", "~> 10.0.3")
  gem.add_development_dependency("simplecov", "~> 0.7.1")
  gem.add_development_dependency("pry", ">= 0.9.11.4")
  gem.add_development_dependency("yard", "~> 0.8.3")
  gem.add_development_dependency("redcarpet", "~> 2.2.2")
  gem.add_development_dependency("github-markup", "~> 0.7.5")
end
