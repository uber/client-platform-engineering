#
# Cookbook Name:: uber_helpers
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

    def delete_file(path_of_file)
      ::File.delete(path_of_file) if ::File.exist?(path_of_file)
    end

    def el_capitan?
      unless node.macos?
        Chef::Log.warn('node.el_capitan? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.11') && node.os_less_than?('10.12')
    end

    def file_age_over_24_hours?(path_of_file)
      file_age_over?(path_of_file, 86400)
    end

    def file_age_over?(path_of_file, seconds)
      age_length = false
      if path_of_file.nil?
        Chef::Log.warn('node.file_age_over - cannot determine path')
        return age_length
      elsif ::File.exist?(path_of_file)
        file_modified_time = File.mtime(path_of_file).to_i
        diff_time = Time.now.to_i - file_modified_time
        age_length = diff_time > seconds
      end
      age_length
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

    def debian_min_package_installed?(pkg_identifier, pkg_version)
      unless node.ubuntu?
        Chef::Log.warn('node.debian_package_installed? called on non-ubuntu system!')
        false
      end
      installed_pkg_version = shell_out(
        "dpkg -s \"#{pkg_identifier}\"",
      ).run_command.stdout.to_s[/Version: (.*)/, 1]
      # Compare the installed version to the maximum version
      if installed_pkg_version.nil?
        Chef::Log.warn("Package #{pkg_identifier} returned nil.")
        false
      end
      Gem::Version.new(installed_pkg_version) >= Gem::Version.new(pkg_version)
    rescue StandardError
      return false
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

    def chef_version
      node['chef_packages']['chef']['version']
    end

    def at_least_chef12?
      at_least?(chef_version, '12.0.0')
    end

    def at_least_chef13?
      at_least?(chef_version, '13.0.0')
    end

    def at_least_chef14?
      at_least?(chef_version, '14.0.0')
    end

    def at_least_chef15?
      at_least?(chef_version, '15.0.0')
    end

    def powershell_package_provider?(pkg_identifier)
      status = false
      unless node.windows?
        Chef::Log.warn('node.powershell_package_provider? called on non-windows device!')
        return false
      end
      require 'chef/mixin/powershell_out'
      powershell_cmd = "(Get-PackageProvider -Name \"#{pkg_identifier}\").Name -eq \"#{pkg_identifier}\" | "\
      'ConvertTo-Json'
      cmd = powershell_out(powershell_cmd).stdout.chomp.strip
      if cmd.nil? || cmd.empty?
        return status
      else
        status = Chef::JSONCompat.parse(cmd)
      end
      status
    end

    def powershell_module?(pkg_identifier)
      status = false
      unless node.windows?
        Chef::Log.warn('node.powershell_module_installed? called on non-windows device!')
        return false
      end
      require 'chef/mixin/powershell_out'
      powershell_cmd = "(Get-InstalledModule -Name \"#{pkg_identifier}\").Name -eq \"#{pkg_identifier}\" | "\
      'ConvertTo-Json'
      cmd = powershell_out(powershell_cmd).stdout.chomp.strip
      if cmd.nil? || cmd.empty?
        return status
      else
        status = Chef::JSONCompat.parse(cmd)
      end
      status
    end

    def dell_hw?
      unless node.windows?
        Chef::Log.warn('node.dell_hw? called on non-windows device!')
        return false
      end
      require 'chef/mixin/powershell_out'
      powershell_cmd = '(Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer'
      cmd = powershell_out(powershell_cmd).stdout.to_s
      if cmd.include?('Dell')
        return true
      else
        return false
      end
    end

    def connection_reachable?(destination)
      unless node.macos? || node.windows?
        Chef::Log.warn('node.connection_reachable? called on non-macOS/windows device!')
        return false
      end
      status = false
      if node.macos?
        cmd = shell_out("/sbin/ping #{destination} -c 1")
      elsif node.windows?
        powershell_cmd = "Test-Connection #{destination} -Count 1 -Quiet"
        cmd = powershell_out(powershell_cmd)
      end
      if cmd.stdout.nil? || cmd.stdout.empty?
        return status
      elsif node.macos?
        # If connected, will return 0, timeout is 68.
        status = cmd.exitstatus.zero?
      elsif node.windows?
        # Powershell returns a string of True/False, which ruby can't natively handle, so we downcase everything and use
        # JSON library to convert it to a BOOL.
        status = Chef::JSONCompat.parse(cmd.stdout.chomp.downcase)
      end
      status
    end

    def port_open?(destination, port, timeout = 1)
      socket = Socket.new(:INET, :STREAM)
      # This will fail if DNS cannot resolve
      begin
        remote_addr = Socket.sockaddr_in(port, destination)
      rescue SocketError
        return false
      end
      # Forced rescue as this always fails
      # rubocop:disable Lint/HandleExceptions
      begin
        socket.connect_nonblock(remote_addr)
      rescue Errno::EINPROGRESS
      end
      # rubocop:enable Lint/HandleExceptions
      sockets = IO.select(nil, [socket], nil, timeout)[1]
      if sockets
        true
      else
        false
      end
    end
  end
end
