# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Clavem
  # The current version of clavem, according to semantic versioning.
  #
  # @see http://semver.org
  module Version
    # The major version.
    MAJOR = 2

    # The minor version.
    MINOR = 1

    # The patch version.
    PATCH = 0

    # The current version of clavem.
    STRING = [MAJOR, MINOR, PATCH].compact.join(".")
  end
end
