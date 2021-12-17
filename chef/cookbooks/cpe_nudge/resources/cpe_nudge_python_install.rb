#
# Cookbook:: cpe_nudge
# Resources:: cpe_nudge_python_install
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_nudge_python_install
provides :cpe_nudge_python_install, :os => 'darwin'

default_action :manage

action :manage do
  install if install? && !uninstall?
  uninstall if uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def base_path
    node['cpe_nudge']['nudge-python']['base_path']
  end

  def custom_resources?
    node['cpe_nudge']['nudge-python']['custom_resources']
  end

  def install?
    node['cpe_nudge']['nudge-python']['install']
  end

  def uninstall?
    node['cpe_nudge']['nudge-python']['uninstall']
  end

  def launchagent_label
    node.nudge_launchctl_label('python', 'launchagent_identifier')
  end

  def launchagent_path
    node.nudge_launchctl_path('python', 'launchagent_identifier')
  end

  def install
    unless ::File.exists?(node['cpe_nudge']['nudge-python']['python_path'])
      Chef::Log.warn("Python defined in node['cpe_nudge']['nudge-python']['python_path'] is not installed.")
      return
    end
    # Create nudge base folders
    [
      base_path,
      ::File.join(base_path, 'Resources'),
      ::File.join(base_path, 'Resources', 'nudge.nib'),
    ].each do |dir|
      directory dir do
        owner root_owner
        group node['root_group']
        mode '0755'
      end
    end

    # Create Log folder with 777 permissions so user agent can write to it.
    directory ::File.join(base_path, 'Logs') do
      owner root_owner
      group node['root_group']
      mode '0777'
    end

    # Create Log file with 777 permissions so user agent can write to it.
    file ::File.join(base_path, 'Logs', 'nudge.log') do
      mode '0777'
    end

    # nudge files
    nudge_files = [
      'gurl.py',
      'nibbler.py',
      'nudge',
    ]

    # Install nudge files
    # If we are updating nudge, we need to disable the launch agent.
    # cpe_launchd will turn it back on later in the run so we don't have a
    # mismatch in what's loaded in memory and what's on disk
    nudge_files.each do |item|
      cookbook_file ::File.join(base_path, 'Resources', item) do
        owner root_owner
        group node['root_group']
        mode '0755'
        path ::File.join(base_path, 'Resources', item)
        source "nudge-python/resources/#{item}"
        notifies :disable, "launchd[#{launchagent_label}]", :immediately if ::File.exists?(launchagent_path)
      end
    end

    # nudge resource files
    nudge_resource_files = [
      'company_logo.png',
      'update_ss.png',
    ]

    # Figure out the path of the resource files
    if custom_resources?
      source_path = 'custom'
    else
      source_path = 'resources'
    end

    # Install nudge resource files
    nudge_resource_files.each do |item|
      cookbook_file ::File.join(base_path, 'Resources', item) do
        owner root_owner
        group node['root_group']
        mode '0755'
        path ::File.join(base_path, 'Resources', item)
        source "nudge-python/#{source_path}/#{item}"
        notifies :disable, "launchd[#{launchagent_label}]", :immediately if ::File.exists?(launchagent_path)
      end
    end

    # nudge nib files
    nudge_nib_files = [
      'designable.nib',
      'keyedobjects.nib',
    ]

    # Install nudge nib files
    nudge_nib_files.each do |item|
      cookbook_file ::File.join(base_path, 'Resources', 'nudge.nib', item) do
        owner root_owner
        group node['root_group']
        mode '0755'
        path "/Library/nudge/Resources/nudge.nib/#{item}"
        source "nudge-python/resources/nudge.nib/#{item}"
        notifies :disable, "launchd[#{launchagent_label}]", :immediately if ::File.exists?(launchagent_path)
      end
    end

    # Triggered Launch Agent action
    launchd launchagent_label do
      action :nothing
      type 'agent'
    end
  end

  def uninstall
    # Delete nudge directory
    directory base_path do
      action :delete
      recursive true
    end

    # Delete Launch Agent
    launchd launchagent_label do
      action :delete
      only_if { ::File.exist?(launchagent_path) }
      type 'agent'
    end
  end
end
