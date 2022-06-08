#
# Cookbook:: uber_helpers
# Libraries:: node_utils
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
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
          return true if profile['ProfileIdentifier'] == profileid && profile.to_s.include?(kextid)
          # Two methods to do here. Explicitly look at the array or convert
          # to string.
          # Array would be profile['ProfileItems'][0]['PayloadContent']\
          # ['AllowedTeamIdentifiers'].include?(kextid)
          # Opting for the string since it's less likely to fail.
        end
      end
      false
    end

    ## Looks for a team id within the profileidentifier specified
    def _parse_sext_profile_removal(profileid, kextid, teamid, profiles)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      if profiles.key?('_computerlevel')
        profiles['_computerlevel'].each do |profile|
          if profile['ProfileIdentifier'] == profileid
            removable_extensions = profile['ProfileItems'][0]['PayloadContent']['RemovableSystemExtensions']
            unless removable_extensions&.nil?
              removable_extensions.each do |key, value|
                return true if key == teamid && value.to_s.include?(kextid)
              end
            end
          end
        end
      end
      false
    end

    ## Will match any top level keys on a profile
    # term is the term to match against
    # key is what key to match (ProfileIdentifier, ProfileDisplayName, etc)
    # profiles is a hash containing all the currently installed profiles
    def _parse_profiles(type, value, profiles, mdm = nil)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      if profiles.key?('_computerlevel')
        profiles['_computerlevel'].each do |profile|
          profile_type = profile[type]
          if mdm == 'ws1' && type == 'ProfileDisplayName'
            profile_type = profile_type.split('/V_')[0]
          end
          return true if profile_type == value
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
          return true if profile['ProfileIdentifier'] == profile_identifier && profile.to_s.include?(profile_content)
        end
      end
      false
    end

    def _parse_user_profiles(type, value, profiles, mdm = nil)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      if profiles.key?(node.console_user)
        profiles[node.console_user].each do |profile|
          profile_type = profile[type]
          if mdm == 'ws1' && type == 'ProfileDisplayName'
            profile_type = profile_type.split('/V_')[0]
          end
          return true if profile_type == value
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

    def _ws1_profile_version(display_name, profiles)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      # WS1 will never have a V_0 profile
      profile_version = '0'
      if profiles.key?('_computerlevel')
        profiles['_computerlevel'].each do |profile|
          if profile['ProfileDisplayName'].nil?
            Chef::Log.warn("profile (#{profile['ProfileIdentifier']}) missing DisplayName key")
            next
          end
          profile_contents = profile['ProfileDisplayName'].split('/V_')
          return profile_contents[1] if profile_contents[0] == display_name
        end
      end
      profile_version
    end

    def _ws1_user_profile_version(display_name, profiles)
      fail 'profiles XML parsing cannot be nil!' if profiles.nil?
      fail 'profiles XML parsing must be a Hash!' unless profiles.is_a?(Hash)

      # WS1 will never have a V_0 profile
      profile_version = '0'
      if profiles.key?(node.console_user)
        profiles[node.console_user].each do |profile|
          if profile['ProfileDisplayName'].nil?
            Chef::Log.warn("profile (#{profile['ProfileIdentifier']}) missing DisplayName key")
            next
          end
          profile_contents = profile['ProfileDisplayName'].split('/V_')
          return profile_contents[1] if profile_contents[0] == display_name
        end
      end
      profile_version
    end

    def at_least?(version1, version2)
      Gem::Version.new(version1) >= Gem::Version.new(version2)
    end

    def at_least_or_lower?(version1, version2)
      Gem::Version.new(version1) <= Gem::Version.new(version2)
    end

    def bionic?
      unless ubuntu?
        Chef::Log.warn('node.bionic? called on non-ubuntu system')
        return
      end
      return node['platform_version'].eql?('18.04')
    end

    def catalina?
      unless macos?
        Chef::Log.warn('node.catalina? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.15') && node.os_less_than?('10.16')
    end

    def big_sur?
      unless macos?
        Chef::Log.warn('node.big_sur? called on non-macOS!')
        return
      end
      return node.os_at_least?('11.0') && node.os_less_than?('12.0') || \
      (node.os_at_least?('10.16') && node.os_less_than?('10.17'))
    end

    def monterey?
      unless macos?
        Chef::Log.warn('node.monterey? called on non-macOS!')
        return
      end
      return node.os_at_least?('12.0') && node.os_less_than?('13.0') || \
      (node.os_at_least?('10.17') && node.os_less_than?('10.18'))
    end

    def ventura?
      unless macos?
        Chef::Log.warn('node.ventura? called on non-macOS!')
        return
      end
      return node.os_at_least?('13.0') && node.os_less_than?('14.0') || \
      (node.os_at_least?('10.18') && node.os_less_than?('10.19'))
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
      unless macos?
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
      unless macos?
        Chef::Log.warn('node.high_sierra? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.13') && node.os_less_than?('10.14')
    end

    def kext_profile_contains_teamid?(kextid, profileid)
      unless macos?
        Chef::Log.warn('node.kext_profile_contains_teamid called on non-macOS!')
      end
      return false if profileid.nil?

      node._parse_kext_profile(profileid, kextid, _config_profiles)
    end

    def sext_profile_removal_contains_extension?(sextid, teamid, profileid)
      unless macos?
        Chef::Log.warn('node.sext_profile_removal_contains_extension called on non-macOS!')
      end
      return false if profileid.nil?

      node._parse_sext_profile_removal(profileid, sextid, teamid, _config_profiles)
    end

    def less_than?(version1, version2)
      Gem::Version.new(version1) < Gem::Version.new(version2)
    end

    def logged_in_user
      unless debian_family?
        Chef::Log.warn('node.logged_in_user called on non-Debian!')
        return
      end
      Etc.getlogin
    end

    def logged_on_user_profile
      unless windows?
        Chef::Log.warn('node.logged_on_user_profile called on non-Windows!')
        return
      end
      ps_cmd = <<~PSCRIPT
        $userProfile = Get-WmiObject -Class "Win32_UserProfile" -Filter "Special = 'False' and LastUseTime != NULL" |
        Sort-Object -Property LastUseTime | Select-Object -Last 1 | Select-Object -Property LocalPath, SID
        $user = $userProfile.LocalPath.substring(9)
        $hash = @{LastLoggedOnUser = "CORP\\$user"; LastLoggedOnUserSID = $userProfile.SID} | ConvertTo-Json
        return $hash
      PSCRIPT
      cmd = node.powershell_out(ps_cmd).stdout.to_str.chomp!
      Chef::JSONCompat.parse(cmd)
    end

    def logged_on_user_registry
      unless windows?
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
      return u.select! { |k, _| k =~ /user/i } unless node.vdi?

      return logged_on_user_profile
    end

    def macos_application_version(apppath, key)
      unless macos?
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
      unless macos?
        Chef::Log.warn('node.macos_cert_installed? called on non-OS X!')
        return false
      end
      shell_out(
        "/usr/bin/security find-certificate -c \"#{cert_name}\" -Z /Library/Keychains/System.keychain",
      ).exitstatus.zero?
    end

    def macos_system_cert_hash?(cert_name)
      unless macos?
        Chef::Log.warn('node.macos_cert_hash? called on non-OS X!')
        return ''
      end
      shell_out(
        "/usr/bin/security find-certificate -c \"#{cert_name}\" -Z /Library/Keychains/System.keychain",
      ).run_command.stdout.to_s[/SHA-256 hash: (.*)/, 1]
    end

    def macos_package_installed?(pkg_identifier, pkg_version)
      unless macos?
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

    def macos_min_package_installed?(pkg_identifier, pkg_version)
      unless macos?
        Chef::Log.warn('node.macos_min_package_installed? called on non-OS X!')
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
      Gem::Version.new(installed_pkg_version) >= Gem::Version.new(pkg_version)
    end

    def macos_package_present?(pkg_identifier)
      unless macos?
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
      unless macos?
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
      unless macos?
        Chef::Log.warn('node.profile_contains_content called on non-macOS!')
        return
      end
      _parse_profile_contents(profile_content, profile_identifier,
                              _config_profiles)
    end

    def profile_installed?(type, value, mdm = nil)
      unless macos?
        Chef::Log.warn('node.profile_installed called on non-macOS!')
        return
      end
      _parse_profiles(type, value, _config_profiles, mdm)
    end

    def sierra?
      unless macos?
        Chef::Log.warn('node.sierra? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.12') && node.os_less_than?('10.13')
    end

    def user_profile_installed?(type, value, mdm = nil)
      unless macos?
        Chef::Log.warn('node.user_profile_installed called on non-macOS!')
        return
      end
      _parse_user_profiles(type, value, _user_config_profiles, mdm)
    end

    def win_min_package_installed?(pkg_identifier, min_pkg)
      unless windows?
        false
      end
      installed_pkg_version = UberHelpers::WinUtils.win_pkg_ver(pkg_identifier)
      # Compare the installed version to the minimum version
      false if installed_pkg_version.nil?
      Gem::Version.new(installed_pkg_version) >= Gem::Version.new(min_pkg)
    end

    def win_max_package_installed?(pkg_identifier, max_pkg)
      unless windows?
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
      unless debian_family?
        Chef::Log.warn('node.debian_package_installed? called on non-Debian system!')
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

    def ws1_min_profile_installed?(display_name, version)
      unless macos?
        Chef::Log.warn('node.ws1_min_profile_installed called on non-macOS!')
        return
      end
      installed_version = _ws1_profile_version(display_name, _config_profiles)
      if installed_version == '0'
        Chef::Log.warn("node.ws1_min_profile_installed did not find profile (#{display_name}) installed!")
        return false
      end
      if installed_version.nil?
        Chef::Log.warn("node.ws1_min_profile_installed profile (#{display_name}) compared does not have a version. "\
          'Is this actually a ws1 profile?')
        return false
      end
      Gem::Version.new(installed_version) >= Gem::Version.new(version)
    end

    def ws1_min_user_profile_installed?(display_name, version)
      unless macos?
        Chef::Log.warn('node.ws1_user_min_profile_installed called on non-macOS!')
        return
      end
      installed_version = _ws1_user_profile_version(display_name, _user_config_profiles)
      if installed_version == '0'
        Chef::Log.warn("node.ws1_min_user_profile_installed did not find profile (#{display_name}) installed!")
        return false
      end
      if installed_version.nil?
        Chef::Log.warn("node.ws1_min_user_profile_installed profile (#{display_name}) compared does not have a "\
          'version. Is this actually a ws1 profile?')
        return false
      end
      Gem::Version.new(installed_version) >= Gem::Version.new(version)
    end

    def yosemite?
      unless macos?
        Chef::Log.warn('node.yosemite? called on non-OS X!')
        return
      end
      return node.os_at_least?('10.10') && node.os_less_than?('10.11')
    end

    def cros?
      unless debian_family?
        Chef::Log.warn('node.cros? called on non debian!')
        return
      end
      return false unless ::File.exists?('/sys/devices/virtual/dmi/id/bios_vendor')

      return ::File.foreach('/sys/devices/virtual/dmi/id/bios_vendor').grep(/crosvm/i).any?
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

    def at_least_chef16?
      at_least?(chef_version, '16.0.0')
    end

    def at_least_chef17?
      at_least?(chef_version, '17.0.0')
    end

    def powershell_package_provider?(pkg_identifier)
      status = false
      unless windows?
        Chef::Log.warn('node.powershell_package_provider? called on non-windows device!')
        return false
      end
      require 'chef/mixin/powershell_out'
      powershell_cmd = '(Get-PackageProvider -WarningAction SilentlyContinue).Name | ConvertTo-Json'
      cmd = powershell_out(powershell_cmd).stdout.to_s
      if cmd.nil? || cmd.empty?
        return status
      else
        status = Chef::JSONCompat.parse(cmd).include?(pkg_identifier)
      end

      status
    end

    def powershell_module?(pkg_identifier)
      status = false
      unless windows?
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
      unless windows?
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
      unless macos? || windows? || debian_family?
        Chef::Log.warn('node.connection_reachable? called on non-macOS/windows/ubuntu device!')
        return false
      end
      status = false
      if macos?
        cmd = shell_out("/sbin/ping #{destination} -c 1")
      elsif debian_family?
        cmd = shell_out("/bin/ping #{destination} -c 2")
      elsif windows?
        powershell_cmd = "Test-Connection #{destination} -Count 1 -Quiet"
        cmd = powershell_out(powershell_cmd)
      end
      if cmd.stdout.nil? || cmd.stdout.empty?
        return status
      elsif macos? || debian_family?
        # If connected, will return 0, timeout is 68.
        status = cmd.exitstatus.zero?
      elsif windows?
        # Powershell returns a string of True/False, which ruby can't natively handle, so we downcase everything and use
        # JSON library to convert it to a BOOL.
        status = Chef::JSONCompat.parse(cmd.stdout.chomp.downcase)
      end

      status
    end

    def macos_os_sub_version
      @macos_os_sub_version ||=
        begin
          unless macos?
            Chef::Log.warn('node.macos_os_sub_version called on non-OS X!')
            return '0'
          end
          cmd = shell_out('/usr/sbin/sysctl -n kern.osversion').run_command.stdout
          if cmd.nil?
            Chef::Log.warn('node.macos_os_sub_version returned nil')
            return '0'
          end
          cmd.strip
        end
    end

    def orbit_token
      unless macos?
        return nil
      end

      orbit_token_path = '/opt/orbit/identifier'

      if ::File.exists?(orbit_token_path)
        return ::File.read(orbit_token_path)
      else
        return nil
      end
    end

    def macos_mutate_version(version)
      # This is stupid, but it works from 10.7 and higher (to date), so this is
      # _likely_ safe.
      # Split the version first - 19F101 becomes ["19", "F", "101"]
      # Reject blank values: 19F101FF would otherwise be ["19", "F", "101", "F", "", "F"]
      split_version = version.split(/([a-z]|[A-Z])/).reject(&:empty?)
      # Join the list with dots and replace letters with numbers
      # ["19", "F", "101"] => 19.F.101 => 19.5.101
      split_version.join('.').tr('ABCDEFGHIJ', '0123456789')
    end

    def mac_os_sub_version_at_least?(version)
      Gem::Version.new(macos_mutate_version(macos_os_sub_version)) >= Gem::Version.new(macos_mutate_version(version))
    rescue ArgumentError
      Chef::Log.warn('node.mac_os_sub_version_at_least? given a malformed version')
      return false
    end

    def mac_os_sub_version_at_least_or_lower?(version)
      Gem::Version.new(macos_mutate_version(macos_os_sub_version)) <= Gem::Version.new(macos_mutate_version(version))
    rescue ArgumentError
      Chef::Log.warn('node.mac_os_sub_version_at_least_or_lower? given a malformed version')
      return false
    end

    def mac_os_sub_version_greater_than?(version)
      Gem::Version.new(macos_mutate_version(macos_os_sub_version)) > Gem::Version.new(macos_mutate_version(version))
    rescue ArgumentError
      Chef::Log.warn('node.mac_os_sub_version_greater_than? given a malformed version')
      return false
    end

    def mac_os_sub_version_less_than?(version)
      Gem::Version.new(macos_mutate_version(macos_os_sub_version)) < Gem::Version.new(macos_mutate_version(version))
    rescue ArgumentError
      Chef::Log.warn('node.mac_os_sub_version_less_than? given a malformed version')
      return false
    end

    def port_open?(destination, port, timeout = 1)
      begin
        socket = Socket.tcp(destination, port, :connect_timeout => timeout)
      rescue Errno::ETIMEDOUT
        Chef::Log.warn("node.port_open? #{destination} timed out")
        return false
      rescue SocketError
        Chef::Log.warn("node.port_open? cannot resolve #{destination}")
        return false
      rescue Errno::ECONNREFUSED
        Chef::Log.warn("node.port_open? #{destination} connection refused")
        return false
      rescue Errno::EHOSTUNREACH
        Chef::Log.warn("node.port_open? #{destination} host unreachable")
        return false
      end
      if socket
        unless socket.closed?
          socket.close
        end
        true
      else
        false
      end
    end

    def distinguished_name?(ou_identifier)
      status = false
      unless windows? || macos?
        Chef::Log.warn('node.distinguished_name? called on non-windows or macos device!')
        return false
      end
      dn = node.machine['distinguishedName']
      if dn.nil? || dn.empty?
        return status
      else
        status = dn.include?(ou_identifier)
      end

      return status
    end

    # function returns an array of bools [ bool, bool ]
    # first element is to indicate if the extension queried is enabled/disabled
    # second element is to indicate if there was an error in the begin/rescue block
    def network_extension_enabled(extension_identifier, type)
      extension_enabled = false
      unless macos?
        Chef::Log.warn('node.network_extension_enabled? called on non-OS X!')
        return false, true
      end

      extension_enabled = false
      extension_error = false

      gnes_path = '/usr/local/bin/gnes'

      if ::File.exist?(gnes_path)
        cmd = shell_out("#{gnes_path} -identifier #{extension_identifier} -type #{type} -stdout-json")
        if cmd.exitstatus.zero?
          begin
            cmd_json = Chef::JSONCompat.parse(cmd.stdout.to_s)
            extension_enabled = cmd_json.nil? ? false : cmd_json['enabled']
          rescue Chef::Exceptions::JSON::ParseError, FFI_Yajl::ParseError
            extension_error = true
            Chef::Log.warn('node.network_extension_enabled threw an error')
          end
        else
          extension_error = true
          Chef::Log.warn('node.network_extension_enabled could not find extension with requested type')
        end
      else
        Chef::Log.info('node.network_extension_enabled could not find gnes binary - reverting to legacy check')
        unless node.at_least?(node.chef_version, '17.7.22')
          Chef::Log.warn('node.network_extension_enabled? requires chef v17.7.22 and higher when using legacy check')
          return false, true
        end
        # Everything is in a key of "$objects"
        begin
          network_extensions = CF::Preferences.get('$objects', 'com.apple.networkextension')
        rescue TypeError
          network_extensions = []
          extension_error = true
          Chef::Log.warn('node.network_extension_enabled threw an error')
        end
        # Apple uses an array of dictionaries but also puts a string or strings before some of
        # the dictionaries to denote what tool it's configuration is, rather than use something sane like <key>.
        # This condition grabs the current index, substracts one and compares it to the previous item in the array.
        # It checks to see if the previous entry was the requested bundle ID and also that the value returned is not a
        # string as Apple also has multiple string entries over and over in the array, which is not the data we need.
        network_extensions.each_with_index do |value, index|
          if network_extensions[index - 1] == extension_identifier && !value.instance_of?(String)
            extension_enabled = value['Enabled']
            break
          end
        end
      end
      return extension_enabled, extension_error
    end

    def system_extension_installed?(extension_identifier)
      # examples: com.crowdstrike.falcon.Agent.systemextension, com.cisco.anyconnect.macos.acsockext.systemextension
      system_extension_installed = false
      unless node.at_least?(node.chef_version, '17.7.22')
        Chef::Log.warn('node.system_extension_installed? requires chef v17.7.22 and higher!')
        return system_extension_installed
      end
      unless macos?
        Chef::Log.warn('node.system_extension_installed? called on non-OS X!')
        return system_extension_installed
      end
      CF::Preferences.get('extensions', '/Library/SystemExtensions/db.plist').each do |k, _v|
        relative_file_path = k['stagedBundleURL']['relative']
        if relative_file_path&.include?(extension_identifier)
          system_extension_installed = ::File.exists?(relative_file_path.split('file://')[1])
        end
      end
      return system_extension_installed
    end

    # Return the Version Number as a String.
    # nil value if the package is not installed.
    def installed_pkg_version(pkg_identifier)
      unless macos?
        Chef::Log.warn('node.installed_pkg_version called on non-OS X!')
        return nil
      end
      installed_pkg_version = shell_out(
        "/usr/sbin/pkgutil --pkg-info \"#{pkg_identifier}\"",
      ).run_command.stdout.to_s[/version: (.*)/, 1]
      Chef::Log.warn("Package #{pkg_identifier} returned nil.") if installed_pkg_version.nil?
      installed_pkg_version
    end

    def macos_install_compat_check(file)
      if ::File.exists?(file)
        return shell_out("/usr/sbin/installer -volinfo -pkg #{file} -plist").stdout.include?('MountPoint')
      else
        Chef::Log.warn("#{file} does not exist.")
        return false
      end
    end

    def installed_pkg_major_version(pkg_identifier)
      version = installed_pkg_version(pkg_identifier)
      version.split('.')[0] unless version.nil?
    end

    def forget_pkg(receipt)
      installed_pkg_version = installed_pkg_version(receipt)
      if installed_pkg_version
        shell_out("/usr/sbin/pkgutil --forget #{receipt}")
      end
    end

    def forget_pkg_with_launchagent(receipt, launcha_path)
      installed_pkg_version = installed_pkg_version(receipt)
      if installed_pkg_version
        shell_out("/usr/sbin/pkgutil --forget #{receipt}")
        if ::File.exists?(launcha_path)
          shell_out("/usr/bin/su -l #{node.console_user} -c "\
            "'/bin/launchctl unload -w #{launcha_path}'", default_env: false) # rubocop:disable Style/HashSyntax
        end
      end
    end

    def forget_pkg_with_launchdaemon(receipt, launchd_path)
      installed_pkg_version = installed_pkg_version(receipt)
      if installed_pkg_version
        shell_out("/usr/sbin/pkgutil --forget #{receipt}")
        if ::File.exists?(launchd_path)
          shell_out("/bin/launchctl unload -w #{launchd_path}", default_env: false) # rubocop:disable Style/HashSyntax
        end
      end
    end

    def chef_solo?
      ChefConfig::Config.chef_server_url.include?('localhost')
    end

    def file_blocked?(target)
      return unless windows?

      ps = "(Get-Item #{target} -Stream \"Zone.Identifier\" -ErrorAction SilentlyContinue) -ne $null | ConvertTo-Json"
      cmd = powershell_out(ps).stdout.to_s
      return Chef::JSONCompat.parse(cmd)
    end

    def at_least_big_sur?
      node.os_at_least?('11.0') || node.os_at_least?('10.16')
    end

    def bplist?(file_path)
      if ::File.exists?(file_path)
        shell_out("/usr/bin/file #{file_path}").run_command.stdout.include?('Apple binary property list')
      end
    end

    def nslookup_txt_records(domain, timeout = 3)
      results = {}
      unless macos?
        Chef::Log.warn('node.nslookup called on non-OS X!')
        return nil
      end
      records = shell_out(
        "/usr/bin/nslookup -type=txt #{domain} -timeout=#{timeout}",
      ).run_command.stdout.to_s.scan(/text = "(.*)"/).flatten
      records.each do |line|
        if domain == 'debug.opendns.com'
          if line.include?('flags') || line.include?('dnscrypt')
            split_line = line.split(' ', 2)
            results[split_line[0]] = split_line[1]
          else
            split_line = line.rpartition(' ')
            results[split_line.first] = split_line.last
          end
        else
          split_line = line.rpartition(' ')
          results[split_line.first] = split_line.last
        end
      end
      results
    end

    def daemon_running?(daemon)
      unless macos?
        Chef::Log.warn('node.dameon_running? called on non-OS X!')
        return nil
      end
      shell_out('/bin/launchctl list').run_command.stdout.to_s[/(.*)#{daemon}/].nil? ? false : true
    end

    def macos_boottime
      unless macos?
        Chef::Log.warn('node.macos_boottime called on non-OS X!')
        return nil
      end
      shell_out('/usr/sbin/sysctl -n kern.boottime').run_command.stdout.to_s[/sec = (.*),/, 1].to_i
    end

    def macos_waketime
      unless macos?
        Chef::Log.warn('node.macos_boottime called on non-OS X!')
        return nil
      end
      shell_out('/usr/sbin/sysctl -n kern.waketime').run_command.stdout.to_s[/sec = (.*),/, 1].to_i
    end

    def macos_kext_loaded?(bundle_identifier)
      unless macos?
        Chef::Log.warn('node.macos_kext_loaded? called on non-macOS!')
        return false
      end
      shell_out(
        "/usr/bin/kmutil showloaded --show loaded --filter \"\'CFBundleIdentifier\' == \'#{bundle_identifier}\'\" "\
        '--variant-suffix release --list-only',
      ).run_command.stdout.to_s.include?(bundle_identifier)
    end

    def macos_process_uptime(process)
      uptime = 0
      unless macos?
        Chef::Log.warn('node.macos_process_time called on non-OS X!')
        return nil
      end
      time = shell_out('/bin/ps acxo etime,command').run_command.stdout.to_s[/(.*) #{process}/, 1]
      unless time.nil?
        safe_time = time.strip.split(':')
        case safe_time.count
        when 3
          uptime = safe_time[0].to_i * 360 + safe_time[1].to_i * 60 + safe_time[2].to_i
        when 2
          uptime = safe_time[0].to_i * 60 + safe_time[1].to_i
        end
      end
      uptime
    end

    def safe_nil_empty?(object)
      object.nil? || object.empty?
    end

    def cpe_launchd_label(cpe_identifier)
      # This portion is taken from cpe_launchd. Since we use cpe_launchd to
      # create our launch agent, the label specified in the attributes will not
      # match the actual label/path that's created. Doing this will result in
      # the right file being targeted.
      if cpe_identifier.start_with?('com')
        name = cpe_identifier.split('.')
        name.delete('com')
        identifier = name.join('.')
        identifier = "#{node['cpe_launchd']['prefix']}.#{identifier}"
      end
      identifier
    end

    def cpe_launchd_path(type, identifier)
      label = cpe_launchd_label(identifier)
      if type == 'agent'
        ::File.join('/Library/LaunchAgents', "#{label}.plist")
      else
        ::File.join('/Library/LaunchDaemons', "#{label}.plist")
      end
    end
  end
end
