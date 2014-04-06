# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "lazier"
require "addressable/uri"

require "clavem/version" if !defined?(Clavem::Version)
require "clavem/server"
require "clavem/authorizer"