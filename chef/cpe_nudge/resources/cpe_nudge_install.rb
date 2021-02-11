#
# Cookbook Name:: cpe_nudge
# Resources:: cpe_nudge_install
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_nudge_install
provides :cpe_nudge_install, :os => 'darwin'

default_action :manage

action :manage do
  install if install? && !uninstall?
  remove if uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def custom_resources?
    node['cpe_nudge']['custom_resources']
  end

  def install?
    node['cpe_nudge']['install']
  end

  def uninstall?
    node['cpe_nudge']['uninstall']
  end

  def label
    # This portion is taken from cpe_launchd. Since we use cpe_launchd to
    # create our launch agent, the label specified in the attributes will not
    # match the actual label/path that's created. Doing this will result in
    # the right file being targeted.
    label = node['cpe_nudge']['la_identifier']
    if label.start_with?('com')
      name = label.split('.')
      name.delete('com')
      label = name.join('.')
      label = "#{node['cpe_launchd']['prefix']}.#{label}"
    end
    label
  end

  def install
    # Create nudge base folders
    [
      '/Library/nudge',
      '/Library/nudge/Resources',
      '/Library/nudge/Resources/nudge.nib',
    ].each do |dir|
      directory dir do
        owner root_owner
        group root_group
        mode '0755'
        action :create
      end
    end

    # Create Log folder with 777 permissions so user agent can write to it.
    directory '/Library/nudge/Logs' do
      owner root_owner
      group root_group
      mode '0777'
      action :create
    end

    # Create Log file with 777 permissions so user agent can write to it.
    file '/Library/nudge/Logs/nudge.log' do
      mode '0777'
      action :create
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
      if item == 'nudge'
        if ::File.exists?(node['cpe_nudge']['python_path'])
          # Python file
          template "/Library/nudge/Resources/#{item}" do
            backup false
            owner root_owner
            group root_group
            mode '0755'
            source item
            variables('shebang' => node['cpe_nudge']['shebang'])
            if ::File.exists?("/Library/LaunchAgents/#{label}.plist")
              notifies :disable, "launchd[#{label}]", :immediately
            end
          end
        else
          # Use legacy nudge if python framework doesn't exist
          cookbook_file "/Library/nudge/Resources/#{item}" do
            backup false
            owner root_owner
            group root_group
            mode '0755'
            action :create
            path "/Library/nudge/Resources/#{item}"
            source "resources/py2_#{item}"
            if ::File.exists?("/Library/LaunchAgents/#{label}.plist")
              notifies :disable, "launchd[#{label}]", :immediately
            end
          end
        end
      else
        cookbook_file "/Library/nudge/Resources/#{item}" do
          owner root_owner
          group root_group
          mode '0755'
          action :create
          path "/Library/nudge/Resources/#{item}"
          if ::File.exists?(node['cpe_nudge']['python_path'])
            source "resources/#{item}"
          # Use legacy nudge if python framework doesn't exist
          else
            source "resources/py2_#{item}"
          end
          if ::File.exists?("/Library/LaunchAgents/#{label}.plist")
            notifies :disable, "launchd[#{label}]", :immediately
          end
        end
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
      cookbook_file "/Library/nudge/Resources/#{item}" do
        owner root_owner
        group root_group
        mode '0755'
        action :create
        path "/Library/nudge/Resources/#{item}"
        source "#{source_path}/#{item}"
        if ::File.exists?("/Library/LaunchAgents/#{label}.plist")
          notifies :disable, "launchd[#{label}]", :immediately
        end
      end
    end

    # nudge nib files
    nudge_nib_files = [
      'designable.nib',
      'keyedobjects.nib',
    ]

    # Install nudge nib files
    nudge_nib_files.each do |item|
      cookbook_file "/Library/nudge/Resources/nudge.nib/#{item}" do
        owner root_owner
        group root_group
        mode '0755'
        action :create
        path "/Library/nudge/Resources/nudge.nib/#{item}"
        source "nudge.nib/#{item}"
        if ::File.exists?("/Library/LaunchAgents/#{label}.plist")
          notifies :disable, "launchd[#{label}]", :immediately
        end
      end
    end

    # Triggered Launch Agent action
    launchd label do
      action :nothing
      type 'agent'
    end

    # Delete old nudge directory
    directory '/Library/Application Support/nudge' do
      action :delete
      recursive true
    end
  end

  def remove
    # Delete old nudge directory
    directory '/Library/Application Support/nudge' do
      action :delete
      recursive true
    end

    # Delete nudge directory
    directory '/Library/nudge' do
      action :delete
      recursive true
    end

    # Delete Launch Agent
    launchd label do
      action :delete
      only_if { ::File.exist?("/Library/LaunchAgents/#{label}.plist") }
      type 'agent'
    end
  end
end
