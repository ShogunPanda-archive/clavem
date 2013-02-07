# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "r18n-desktop"
require "lazier"
require "webrick"
require "erb"

require "clavem/version" if !defined?(Clavem::Version)
require "clavem/authorizer"