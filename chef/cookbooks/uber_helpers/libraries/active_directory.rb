#
# Cookbook:: uber_helpers
# Libraries:: active_directory
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2020-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

class Chef
  class Node
    def _can_query_ad?(domain_hostname, ldaps_domain_hostname)
      ad_bound?(domain_hostname) && connection_reachable?(ldaps_domain_hostname)
    end

    def ad_bound?(domain_hostname)
      status = false
      ad_state = active_directory_state
      if ad_state.nil?
        return status
      elsif macos?
        status = ad_state['General Info']['Active Directory Domain'] == domain_hostname
      elsif windows?
        status = ad_state
      end

      status
    end

    def ad_healthy?(username_to_check)
      status = false
      if macos?
        cmd = shell_out("/usr/bin/id -u #{username_to_check}")
        if cmd.nil?
          return status
        else
          status = cmd.exitstatus.zero?
        end
      end
      status
    end

    def active_directory_state
      status = nil
      if macos?
        cmd = shell_out('/usr/sbin/dsconfigad -show -xml').stdout
      elsif windows?
        # TODO: Move to a full active_directory powershell method.
        powershell_cmd = '(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain'
        cmd = powershell_out(powershell_cmd).stdout
      end
      if cmd.nil? || cmd.empty?
        return status
      elsif macos?
        status = Plist.parse_xml(cmd)
      elsif windows?
        # Powershell returns a string of True/False, which ruby can't natively handle, so we downcase everything and use
        # JSON library to convert it to a BOOL.
        status = Chef::JSONCompat.parse(cmd.chomp.downcase)
      end

      status
    end

    def active_directory_domain
      if macos?
        return node.active_directory_state&.dig('General Info', 'Active Directory Domain')
      elsif windows?
        powershell_cmd = '(Get-WmiObject -Class Win32_ComputerSystem).domain'
        cmd = powershell_out(powershell_cmd).stdout
        return cmd.chomp.downcase
      else
        return nil
      end
    end
  end
end
