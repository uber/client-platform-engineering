#
# Cookbook Name:: cpe_ssh_server
# Resources:: cpe_ssh_server
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_ssh_server
provides :cpe_ssh_server, :platform => 'mac_os_x'
default_action :manage

action :manage do
  manage if node['cpe_ssh_server']['manage']
end

action_class do
  def manage
    # On 10.15 systemsetup needs a PPPC/TCC profile to be able to run setremotelogin.
    # Currently, the TCC profile needs an app bundle to tie to. Since
    # chef-client/chefctl are not bundle apps, nor signed until chef 15, we can no
    # longer adequately manage SSH this way. Instead, we can use launchctl and forcibly
    # load or unload the plist. For some reason Apple didn't block this method.
    if node['cpe_ssh_server']['enable']
      enable
    else
      disable
    end
  end

  def disable
    # Only supported for macOS at the moment
    macos_disable if node.macos?
  end

  def macos_disable
    # Disable SSH
    if node.os_less_than?('10.15')
      execute 'Disable SSH' do
        command '/usr/sbin/systemsetup -f -setremotelogin off'
        only_if { macos_ssh_status('On') }
      end
    else
      launchd 'Disable SSH' do
        action :disable
        path '/System/Library/LaunchDaemons/ssh.plist'
      end
    end
  end

  def enable
    # Only supported for macOS at the moment
    macos_enable if node.macos?
  end

  def macos_enable
    # Enable SSH
    if node.os_less_than?('10.15')
      execute 'Enable SSH' do
        command '/usr/sbin/systemsetup -f -setremotelogin on'
        only_if { macos_ssh_status('Off') }
      end
    else
      launchd 'Enable SSH' do
        action :enable
        path '/System/Library/LaunchDaemons/ssh.plist'
      end
    end
  end

  def macos_ssh_status(desired_state)
    status = false
    if node.macos?
      cmd = shell_out(
        '/usr/sbin/systemsetup -getremotelogin',
      ).stdout.to_s
      if cmd.nil? || cmd.empty?
        return status
      else
        status = cmd.include?(desired_state)
      end
    end
    status
  end
end
