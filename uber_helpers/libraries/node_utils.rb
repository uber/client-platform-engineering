#
# Cookbook Name:: uber_helprs
# Libraries:: node_utils
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

class Chef
  class Node
    def _config_profiles
      @_config_profiles ||=
        begin
          if node.os_at_least?('10.13.0')
            UberHelpers::MacUtils.get_installed_profiles
          else
            UberHelpers::MacUtils.get_installed_profiles_legacy
          end
        rescue Exception => e # rubocop:disable Lint/RescueException
          Chef::Log.warn(
            "Failed to retrieve installed profiles with error #{e}",
          )
          {}
        end
    end

    ## Looks for a team id within the profileidentifier specified
    def _parse_kext_profile(profileid, kextid, profiles)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      if profiles.key?('_computerlevel')
        profiles['_computerlevel'].each do |profile|
          # Only check for kextid if the profile is installed.
          if profile['ProfileIdentifier'] == profileid
            # Two methods to do here. Explicitly look at the array or convert
            # to string.
            # Array would be profile['ProfileItems'][0]['PayloadContent']\
            # ['AllowedTeamIdentifiers'].include?(kextid)
            # Opting for the string since it's less likely to fail.
            return true if profile.to_s.include?(kextid)
          end
        end
      end
      false
    end

    ## Will match any top level keys on a profile
    # term is the term to match against
    # key is what key to match (ProfileIdentifier, ProfileDisplayName, etc)
    # profiles is a hash containing all the currently installed profiles
    def _parse_profiles(type, value, profiles)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      if profiles.key?('_computerlevel')
        profiles['_computerlevel'].each do |profile|
          return true if profile[type] == value
        end
      end
      false
    end

    ## Looks for content specifically in the payload of the profile.
    def _parse_profile_contents(profile_content, profile_identifier, profiles)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      if profiles.key?('_computerlevel')
        profiles['_computerlevel'].each do |profile|
          if profile['ProfileIdentifier'] == profile_identifier
            # Convert the entire hash of the profile to a string.
            return true if profile.to_s.include?(profile_content)
          end
        end
      end
      false
    end

    def _parse_user_profiles(type, value, profiles)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      if profiles.key?(node.console_user)
        profiles[node.console_user].each do |profile|
          return true if profile[type] == value
        end
      end
      false
    end

    def _user_config_profiles
      @_user_config_profiles ||=
        if node.os_at_least?('10.13.0')
          UberHelpers::MacUtils.get_installed_user_profiles(node.console_user)
        else
          UberHelpers::MacUtils.get_installed_user_profiles_legacy(
            node.console_user,
          )
        end
    end

    def at_least?(version1, version2)
      Gem::Version.new(version1) >= Gem::Version.new(version2)
    end

    def at_least_or_lower?(version1, version2)
      Gem::Version.new(version1) <= Gem::Version.new(version2)
    end

    def bionic?
      unless node.ubuntu?
        Chef::Log.warn('node.bionic? called on non-ubuntu system')
        return
      end
      return node['platform_version'].eql?('18.04')
    end

    def catalina?
      unless node.macos?
        Chef::Log.warn('node.catalina? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.15') && node.os_less_than?('10.16')
    end

    def console_user_debian
      unless node.debian_family?
        Chef::Log.warn('node.console_user_debian called on non-Debian!')
        return
      end
      shell_out('/usr/bin/users').stdout.to_s.split(' ')[0]
    end

    def date_at_least?(date)
      Date.today >= Date.parse(date)
    end

    def date_passed?(date)
      Date.today > Date.parse(date)
    end

    def el_capitan?
      unless node.macos?
        Chef::Log.warn('node.el_capitan? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.11') && node.os_less_than?('10.12')
    end

    def file_age_over_24_hours?(path_of_file)
      @file_age_over_24_hours ||=
        begin
          age_length = false
          if ::File.exist?(path_of_file)
            file_modified_time = File.mtime(path_of_file).to_date
            diff_time = (Date.today - file_modified_time).to_i
            age_length = diff_time > 1
          end
          age_length
        end
    end

    def greater_than?(version1, version2)
      Gem::Version.new(version1) > Gem::Version.new(version2)
    end

    def high_sierra?
      unless node.macos?
        Chef::Log.warn('node.high_sierra? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.13') && node.os_less_than?('10.14')
    end

    def kext_profile_contains_teamid?(kextid, profileid)
      unless node.macos?
        Chef::Log.warn('node.kext_profile_contains_teamid called on non-macOS!')
      end
      node._parse_kext_profile(profileid, kextid, _config_profiles)
    end

    def less_than?(version1, version2)
      Gem::Version.new(version1) < Gem::Version.new(version2)
    end

    def logged_in_user
      unless node.ubuntu?
        Chef::Log.warn('node.logged_in_user called on non-Ubuntu!')
        return
      end
      Etc.getlogin
    end

    def logged_on_user_registry
      unless node.windows?
        Chef::Log.warn('node.logged_on_user_registry called on non-Windows!')
        return
      end
      require 'win32/registry'
      logon_reg_key = \
        'SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Authentication\\LogonUI'
      u = ::Win32::Registry::HKEY_LOCAL_MACHINE.open(
        logon_reg_key, ::Win32::Registry::KEY_READ
      ) do |reg|
        reg.to_a.each_with_object({}).each { |(a, _, c), obj| obj[a] = c }
      end
      u.select! { |k, _| k =~ /user/i }
    end

    def macos_application_version(apppath, key)
      unless node.macos?
        Chef::Log.warn('node.macos_application_version called on non-OS X!')
        return ''
      end
      if ::File.exist?(apppath)
        res = Plist.parse_xml(apppath)
        res[key].to_s
      else
        return ''
      end
    rescue NoMethodError => e
      Chef::Log.warn("#{e} on version lookup")
      return ''
    end

    def macos_system_cert_installed?(cert_name)
      unless node.macos?
        Chef::Log.warn('node.macos_cert_installed? called on non-OS X!')
        return false
      end
      shell_out(
        "/usr/bin/security find-certificate -c \"#{cert_name}\" -Z /Library/Keychains/System.keychain",
      ).exitstatus.zero?
    end

    def macos_package_installed?(pkg_identifier, pkg_version)
      unless node.macos?
        Chef::Log.warn('node.macos_package_installed? called on non-OS X!')
        false
      end
      installed_pkg_version = shell_out(
        "/usr/sbin/pkgutil --pkg-info \"#{pkg_identifier}\"",
      ).run_command.stdout.to_s[/version: (.*)/, 1]
      # Compare the installed version to the maximum version
      if installed_pkg_version.nil?
        Chef::Log.warn("Package #{pkg_identifier} returned nil.")
        false
      end
      Gem::Version.new(installed_pkg_version) == Gem::Version.new(pkg_version)
    end

    def macos_package_present?(pkg_identifier)
      unless node.macos?
        Chef::Log.warn('node.macos_package_present? called on non-OS X!')
        return false
      end
      installed_pkg_version = shell_out(
        "/usr/sbin/pkgutil --pkg-info \"#{pkg_identifier}\"",
      ).run_command.stdout.to_s[/version: (.*)/, 1]
      if installed_pkg_version.nil?
        Chef::Log.warn("Package #{pkg_identifier} returned nil.")
        return false
      end
      true
    end

    def mojave?
      unless node.macos?
        Chef::Log.warn('node.mojave? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.14') && node.os_less_than?('10.15')
    end

    def not_eql?(version1, version2)
      Gem::Version.new(version1) != Gem::Version.new(version2)
    end

    def parse_json(path)
      Chef::JSONCompat.parse(::File.read(path))
    end

    def profile_contains_content?(profile_content, profile_identifier)
      unless node.macos?
        Chef::Log.warn('node.profile_contains_content called on non-macOS!')
      end
      _parse_profile_contents(profile_content, profile_identifier,
                              _config_profiles)
    end

    def profile_installed?(type, value)
      unless node.macos?
        Chef::Log.warn('node.profile_installed called on non-macOS!')
      end
      _parse_profiles(type, value, _config_profiles)
    end

    def sierra?
      unless node.macos?
        Chef::Log.warn('node.sierra? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.12') && node.os_less_than?('10.13')
    end

    def trusty?
      unless node.ubuntu?
        Chef::Log.warn('node.trusty? called on non-ubuntu system')
        return
      end
      return node['platform_version'].eql?('14.04')
    end

    def user_profile_installed?(type, value)
      unless node.macos?
        Chef::Log.warn('node.user_profile_installed called on non-macOS!')
        nil
      end
      _parse_user_profiles(type, value, _user_config_profiles)
    end

    def win_min_package_installed?(pkg_identifier, min_pkg)
      unless node.windows?
        false
      end
      installed_pkg_version = UberHelpers::WinUtils.win_pkg_ver(pkg_identifier)
      # Compare the installed version to the minimum version
      false if installed_pkg_version.nil?
      Gem::Version.new(installed_pkg_version) >= Gem::Version.new(min_pkg)
    end

    def win_max_package_installed?(pkg_identifier, max_pkg)
      unless node.windows?
        Chef::Log.warn(
          'node.win_max_package_installed? called on non-windows! system',
        )
        false
      end
      installed_pkg_version = UberHelpers::WinUtils.win_pkg_ver(pkg_identifier)
      # Compare the installed version to the minimum version
      if installed_pkg_version.nil?
        Chef::Log.warn("Package #{pkg_identifier} returned nil.")
        false
      end
      Gem::Version.new(installed_pkg_version) <= Gem::Version.new(max_pkg)
    end

    def write_contents_to_file(path, contents)
      File.open(path, 'w') { |target_file| target_file.write(contents) }
    end

    def xenial?
      unless node.ubuntu?
        Chef::Log.warn('node.xenial? called on non-ubuntu system')
        return
      end
      return node['platform_version'].eql?('16.04')
    end

    def yosemite?
      unless node.macos?
        Chef::Log.warn('node.yosemite? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.10') && node.os_less_than?('10.11')
    end
  end
end
