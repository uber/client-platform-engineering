#
# Cookbook:: cpe_nudge
# Resources:: cpe_nudge_swift_install
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2021-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_nudge_swift_install
provides :cpe_nudge_swift_install, :os => 'darwin'

default_action :manage

action :manage do
  install if install? && !uninstall?
  uninstall if uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def app_path
    node['cpe_nudge']['nudge-swift']['app_path']
  end

  def base_path
    node['cpe_nudge']['nudge-swift']['base_path']
  end

  def custom_resources?
    node['cpe_nudge']['nudge-swift']['custom_resources']
  end

  def launchagent_label
    node.nudge_launchctl_label('swift', 'launchagent_identifier')
  end

  def launchagent_path
    node.nudge_launchctl_path('swift', 'launchagent_identifier')
  end

  def loggerdaemon_label
    node.nudge_launchctl_label('swift', 'loggerdaemon_identifier')
  end

  def loggerdaemon_path
    node.nudge_launchctl_path('swift', 'loggerdaemon_identifier')
  end

  def install?
    node['cpe_nudge']['nudge-swift']['install']
  end

  def manage_pkg?
    node['cpe_nudge']['nudge-swift']['manage_pkg']
  end

  def uninstall?
    node['cpe_nudge']['nudge-swift']['uninstall']
  end

  def install
    custom_resources if custom_resources?
    manage_pkg if manage_pkg?
  end

  def custom_resources
    # Create nudge base folder
    directory base_path do
      owner root_owner
      group node['root_group']
      mode '0755'
    end

    # Install nudge resource files
    [
      'logoDark.png',
      'logoLight.png',
      'screenShotDark.png',
      'screenShotLight.png',
    ].each do |item|
      cookbook_file ::File.join(base_path, item) do
        owner root_owner
        group node['root_group']
        mode '0755'
        source "nudge-swift/custom/#{item}"
        notifies :disable, "launchd[#{launchagent_label}]", :immediately if ::File.exists?(launchagent_path)
      end
    end

    # Triggered Launch Agent action
    launchd launchagent_label do
      action :nothing
      type 'agent'
    end
  end

  def manage_pkg
    # The receipt must be in this function or cpe_remote_pkg will not be idempotent.
    # No idea why other than some weird compile/converge thing.
    receipt = node['cpe_nudge']['nudge-swift']['pkg']['receipt']
    version = node['cpe_nudge']['nudge-swift']['pkg']['version']
    url = node['cpe_nudge']['nudge-swift']['pkg']['url']

    # Bail if version is nil
    unless version.nil?
      # If Nudge goes missing, either by accident or abuse, trigger re-install
      unless ::Dir.exists?(app_path)
        node.forget_pkg_with_launchagent(receipt, launchagent_path)
      end
      # Install Nudge
      cpe_remote_pkg node['cpe_nudge']['nudge-swift']['pkg']['app_name'] do
        allow_downgrade node['cpe_nudge']['nudge-swift']['pkg']['allow_downgrade']
        version version
        checksum node['cpe_nudge']['nudge-swift']['pkg']['checksum']
        receipt receipt
        backup 1
        pkg_url url if url
      end
    end
  end

  def uninstall
    # Delete Launch Agent
    launchd launchagent_label do
      action :delete
      only_if { ::File.exists?(launchagent_path) }
      type 'agent'
    end

    # Delete Launch Daemon
    launchd loggerdaemon_label do
      action :delete
      only_if { ::File.exists?(loggerdaemon_path) }
      type 'daemon'
    end

    # Delete nudge directory
    directory base_path do
      action :delete
      recursive true
    end

    # Delete Application
    directory app_path do
      action :delete
      recursive true
    end

    # Delete log path
    file node['cpe_nudge']['nudge-swift']['loggerdaemon']['standard_out_path'] do
      action :delete
    end

    # Delete JSON preferences
    file node['cpe_nudge']['nudge-swift']['json_path'] do
      action :delete
    end

    # Forget package receipt
    receipt = node['cpe_nudge']['nudge-swift']['pkg']['receipt']
    node.forget_pkg_with_launchagent(receipt, launchagent_path)
  end
end
