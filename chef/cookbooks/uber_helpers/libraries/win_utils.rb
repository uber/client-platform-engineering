#
# Cookbook:: uber_helpers
# Libraries:: win_utils
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

if Chef::Platform.windows?
  module UberHelpers
    class WinUtils
      def self.win_pkg_ver(win_pkg_name)
        require 'win32/registry'
        pkg_version = nil

        # Begin Checking HKEY_LOCAL_MACHINE paths for install.
        {
          'HKEY_LOCAL_MACHINE' => [
            'Software\Microsoft\Windows\CurrentVersion\Uninstall',
            'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
            'Software\Wow6464Node\Microsoft\Windows\CurrentVersion\Uninstall',
          ],
          'HKEY_CURRENT_USER' => [
            'Software\Microsoft\Windows\CurrentVersion\Uninstall',
          ],
        }.each do |reg_loc, reg_path|
          # dont process path if the version has already been discovered
          break unless pkg_version.nil?

          # Begin loop to check and process each registry path
          reg_path.each do |rpath|
            # break out of loop if pkg_version already found
            break unless pkg_version.nil?

            # break if the registry path does not exist
            break unless reg_path_exist?(reg_loc, rpath)

            win32_name = "::Win32::Registry::#{reg_loc}"
            win32_class = Object.const_get(win32_name)
            # Read in the path and get child keys
            reg = win32_class.open(rpath)
            # query each of the subkeys
            reg.each_key do |key|
              # break out of loop if already found
              break unless pkg_version.nil?

              # open subkey and peak inside
              k = reg.open(key)
              begin
                # assign variable to each key
                pkg_name = k['DisplayName']
                pkg_ver = k['DisplayVersion']
                # make sure that the result can get a similiar to exact match.
                if pkg_name && pkg_ver && pkg_name.include?(win_pkg_name)
                  # update the pkg_version from 0 to discovered version.
                  pkg_version = pkg_ver
                  # close the keypath
                  k.close
                  # break out of this path search once a match is made.
                  break
                end
              rescue StandardError
                # process next subkey on error.
                next
              end
              # close the open key only if pkg_version hasnt been found.
              break unless pkg_version.nil?

              k.close
            end
            reg.close
          end
        end
        return pkg_version
      end

      # returns windows friendly version of the provided path,
      # ensures backslashes are used everywhere
      def self.friendly_path(path)
        path.gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR || '\\') if path
      end

      def self.reg_path_exist?(reg_loc, reg_path)
        win32_name = "::Win32::Registry::#{reg_loc}"
        win32_class = Object.const_get(win32_name)
        win32_class.open(reg_path, ::Win32::Registry::KEY_READ)
        return true
      rescue StandardError
        return false
      end
    end
  end
end
