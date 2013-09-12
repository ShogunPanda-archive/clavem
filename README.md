# Introduction

[![Gem Version](https://badge.fury.io/rb/clavem.png)](http://badge.fury.io/rb/clavem)
[![Dependency Status](https://gemnasium.com/ShogunPanda/clavem.png?travis)](https://gemnasium.com/ShogunPanda/clavem)
[![Build Status](https://secure.travis-ci.org/ShogunPanda/clavem.png?branch=master)](http://travis-ci.org/ShogunPanda/clavem)
[![Code Climate](https://codeclimate.com/github/ShogunPanda/clavem.png)](https://codeclimate.com/github/ShogunPanda/clavem)
[![Coverage Status](https://coveralls.io/repos/ShogunPanda/clavem/badge.png)](https://coveralls.io/r/ShogunPanda/clavem)

A local callback server for oAuth web-flow.

http://sw.cow.tc/clavem

http://rdoc.info/gems/clavem

## Usage

clavem allows you to handle a full oAuth authentication flow directly from the console.

Simply instantiate the authorizer and run the authorize method with the URL:

```ruby
require "clavem"

# Initialize your oAuth access.

authorizer = Clavem::Authorizer.new

# Get the token
# You can also handle callback parameter by yourself.
# url += "?oauth_callback=" + authorizer.callback_url
# authorizer.authorize(url, false)
authorizer.authorize(url)

if authorizer.succeeded? then
  access_token = authorizer.token

  # Go on!
else
  # Authorization denied or failed
end
```

Alternatively, you can also specify a timeout and a block to the constructor to customizer the response handling.

See the [documentation](http://rdoc.info/gems/clavem) for more information.

## Use on jRuby

To use on jRuby, you need to install a gem with C extensions which must be compiled.

See jRuby documentation to see how to enabled extensions compilation.

## Contributing to clavem
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (C) 2013 and above Shogun (shogun@cowtech.it).

Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
