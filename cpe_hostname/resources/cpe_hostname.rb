#
# Cookbook Name:: cpe_hostname
# Resources:: cpe_hostname
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_hostname
provides :cpe_hostname
default_action :manage

action :manage do
  enforce if enforce?
end

action_class do
  def check_hostname_macos(type)
    shell_out("/usr/sbin/scutil --get #{type}").stdout.to_s.chomp
  end

  def check_hostname_windows
    shell_out('c:\\Windows\\System32\\HOSTNAME.exe').stdout.to_s.chomp
  end

  def enforce?
    node['cpe_hostname']['enforce']
  end

  def enforce
    hostname = node['cpe_hostname']['hostname']

    # If value isn't specified, don't do anything
    if hostname.nil?
      Chef::Log.warn('cpe_hostname hostname value not set!')
      return
    end

    if node.macos?
      # Don't apply at loginwindow or SetupAssistant
      if %w(loginwindow _mbsetupuser).include?(node.console_user)
        Chef::Log.warn(
          'Device at loginwindow or SetupAssistant - skipping hostname '\
          'enforcement!',
        )
        return
      end
      # Loop through the types of hostnames for macOS and set them
      # LocalHostName cannot have at signs, spaces, dots or underscores.
      # Replace with hyphens.
      fixed_hostname = hostname.gsub(/[@._ ]/, '-')
      %w[
        ComputerName
        HostName
        LocalHostName
      ].each do |type|
        execute "Setting #{type} to #{fixed_hostname}" do
          command "/usr/sbin/scutil --set #{type} #{fixed_hostname}"
          # Reduce CPU cycles by using ohai attributes for hostname
          if type == 'HostName'
            only_if { node['hostname'] != fixed_hostname }
          else
            only_if { check_hostname_macos(type) != fixed_hostname }
          end
        end
      end
    elsif node.windows?
      hostname 'Resetting hostname' do
        hostname node['cpe_hostname']['hostname']
        windows_reboot node['cpe_hostname']['windows_reboot']
        only_if { check_hostname_windows != node['cpe_hostname']['hostname'] }
      end
      return
    elsif node.ubuntu?
      # TODO: write ubuntu portion
      return
    end
  end
end
