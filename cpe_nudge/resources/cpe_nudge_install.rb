#
# Cookbook:: cpe_nudge
# Resources:: cpe_nudge_install
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
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

action_class do
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
      '/Library/Application Support/nudge',
      '/Library/Application Support/nudge/Resources',
      '/Library/Application Support/nudge/Resources/nudge.nib',
    ].each do |dir|
      directory dir do
        group 'wheel'
        owner 'root'
        mode '0755'
        action :create
      end
    end

    # Create Log folder with 777 permissions so user agent can write to it.
    directory '/Library/Application Support/nudge/Logs' do
      group 'wheel'
      owner 'root'
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
    nudge_files.each do |item|
      cookbook_file "/Library/Application Support/nudge/Resources/#{item}" do
        owner 'root'
        group 'wheel'
        mode '0755'
        action :create
        path "/Library/Application Support/nudge/Resources/#{item}"
        source "resources/#{item}"
        # If we are updating nudge, we need to disable the launch agent.
        # cpe_launchd will turn it back on later in the run so we don't have a
        # mismatch in what's loaded in memory and what's on disk
        if item == 'nudge'
          notifies :disable, "launchd[#{label}]"
        end
      end
    end

    # Triggered Launch Agent action
    launchd label do
      action :nothing
      only_if { ::File.exist?("/Library/LaunchAgents/#{label}.plist") }
      type 'agent'
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
      cookbook_file "/Library/Application Support/nudge/Resources/#{item}" do
        owner 'root'
        group 'wheel'
        mode '0755'
        action :create
        path "/Library/Application Support/nudge/Resources/#{item}"
        source "#{source_path}/#{item}"
      end
    end

    # nudge nib files
    nudge_nib_files = [
      'designable.nib',
      'keyedobjects.nib',
    ]

    # Install nudge nib files
    nudge_nib_files.each do |item|
      cookbook_file "/Library/Application Support/nudge/Resources/nudge.nib/#{item}" do
        owner 'root'
        group 'wheel'
        mode '0755'
        action :create
        path "/Library/Application Support/nudge/Resources/nudge.nib/#{item}"
        source "nudge.nib/#{item}"
      end
    end
  end

  def remove
    # Delete nudge directory
    directory '/Library/Application Support/nudge' do
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
