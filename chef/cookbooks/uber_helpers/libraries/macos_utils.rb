#
# Cookbook:: uber_helpers
# Libraries:: macos_utils
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

module UberHelpers
  class MacUtils
    def self.get_installed_profiles
      @get_installed_profiles ||= begin
        Plist.parse_xml(`/usr/bin/profiles show -output stdout-xml`)
      end
    end

    def self.get_installed_profiles_legacy
      @get_installed_profiles_legacy ||= begin
        Plist.parse_xml(`/usr/bin/profiles -Co stdout-xml`)
      end
    end

    def self.get_installed_user_profiles(user)
      @get_installed_user_profiles ||= begin
        Plist.parse_xml(
          `/usr/bin/profiles show -output stdout-xml -user #{user}`,
        )
      end
    end

    def self.get_installed_user_profiles_legacy(user)
      @get_installed_user_profiles_legacy ||= begin
        Plist.parse_xml(
          `/usr/bin/profiles -Lo stdout-xml -U #{user}`,
        )
      end
    end
  end
end
