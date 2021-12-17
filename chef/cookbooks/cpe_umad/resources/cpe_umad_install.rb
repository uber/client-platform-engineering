#
# Cookbook:: cpe_umad
# Resources:: cpe_umad_install
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

resource_name :cpe_umad_install
provides :cpe_umad_install, :os => 'darwin'

default_action :manage

action :manage do
  install if install? && !uninstall?
  remove if uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def custom_resources?
    node['cpe_umad']['custom_resources']
  end

  def install?
    node['cpe_umad']['install']
  end

  def uninstall?
    node['cpe_umad']['uninstall']
  end

  def label(cpe_identifier)
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

  def install
    # Create umad base folders
    [
      '/Library/umad',
      '/Library/umad/Resources',
      '/Library/umad/Resources/umad.nib',
    ].each do |dir|
      directory dir do
        owner root_owner
        group node['root_group']
        mode '0755'
        action :create
      end
    end

    # Create Log folder with 777 permissions so user agent can write to it.
    directory '/Library/umad/Logs' do
      owner root_owner
      group node['root_group']
      mode '0777'
      action :create
    end

    # Create Log file with 777 permissions so user agent can write to it.
    file '/Library/umad/Logs/umad.log' do
      mode '0777'
      action :create
    end

    # UMAD files
    umad_files = [
      'FoundationPlist.py',
      'nibbler.py',
      'umad',
      'umad_check_dep_record',
      'umad_trigger_nag',
    ]

    ld_la_identifiers = [
      label(node['cpe_umad']['la_identifier']),
      label(node['cpe_umad']['ld_dep_identifier']),
      label(node['cpe_umad']['ld_nag_identifier']),
    ]

    # Install UMAD files
    # If we are updating umad, we need to disable the launch agent and
    # daemons. cpe_launchd will turn it back on later in the run so we
    # don't have a mismatch in what's loaded in memory and what's on disk
    umad_files.each do |item|
      umad_bins = ['umad', 'umad_check_dep_record', 'umad_trigger_nag']
      if umad_bins.include?(item)
        if ::File.exists?(node['cpe_umad']['python_path'])
          # Python file
          template "/Library/umad/Resources/#{item}" do
            backup false
            owner root_owner
            group node['root_group']
            mode '0755'
            source item
            variables('shebang' => node['cpe_umad']['shebang'])
            ld_la_identifiers.each do |identifier|
              if ::File.exists?("/Library/LaunchAgents/#{identifier}.plist") \
                || ::File.exists?("/Library/LaunchDaemons/#{identifier}.plist")
                notifies :disable, "launchd[#{identifier}]", :immediately
              end
            end
          end
        else
          # Use legacy nudge if python framework doesn't exist
          cookbook_file "/Library/umad/Resources/#{item}" do
            backup false
            owner root_owner
            group node['root_group']
            mode '0755'
            action :create
            path "/Library/umad/Resources/#{item}"
            source "resources/py2_#{item}"
            ld_la_identifiers.each do |identifier|
              if ::File.exists?("/Library/LaunchAgents/#{identifier}.plist") \
                || ::File.exists?("/Library/LaunchDaemons/#{identifier}.plist")
                notifies :disable, "launchd[#{identifier}]", :immediately
              end
            end
          end
        end
      elsif item == 'FoundationPlist.py' && ::File.exists?(node['cpe_umad']['python_path'])
        # FoundationPlist is not needed on embedded python version of UMAD
        next
      else
        cookbook_file "/Library/umad/Resources/#{item}" do
          owner root_owner
          group node['root_group']
          mode '0755'
          action :create
          path "/Library/umad/Resources/#{item}"
          if ::File.exists?(node['cpe_umad']['python_path'])
            source "resources/#{item}"
          # Use legacy UMAD if python framework doesn't exist
          else
            source "resources/py2_#{item}"
          end
          ld_la_identifiers.each do |identifier|
            if ::File.exists?("/Library/LaunchAgents/#{identifier}.plist") \
              || ::File.exists?("/Library/LaunchDaemons/#{identifier}.plist")
              notifies :disable, "launchd[#{identifier}]", :immediately
            end
          end
        end
      end
    end

    # UMAD resource files
    umad_resource_files = [
      'company_logo.png',
      'nag_ss.png',
      'uamdm_ss.png',
    ]

    # Figure out the path of the resource files
    if custom_resources?
      source_path = 'custom'
    else
      source_path = 'resources'
    end

    # Install UMAD resource files
    umad_resource_files.each do |item|
      cookbook_file "/Library/umad/Resources/#{item}" do
        owner root_owner
        group node['root_group']
        mode '0755'
        action :create
        path "/Library/umad/Resources/#{item}"
        source "#{source_path}/#{item}"
        ld_la_identifiers.each do |identifier|
          if ::File.exists?("/Library/LaunchAgents/#{identifier}.plist") \
            || ::File.exists?("/Library/LaunchDaemons/#{identifier}.plist")
            notifies :disable, "launchd[#{identifier}]", :immediately
          end
        end
      end
    end

    # UMAD nib files
    umad_nib_files = [
      'designable.nib',
      'keyedobjects.nib',
    ]

    # Install UMAD nib files
    umad_nib_files.each do |item|
      cookbook_file "/Library/umad/Resources/umad.nib/#{item}" do
        owner root_owner
        group node['root_group']
        mode '0755'
        action :create
        path "/Library/umad/Resources/umad.nib/#{item}"
        source "umad.nib/#{item}"
        ld_la_identifiers.each do |identifier|
          if ::File.exists?("/Library/LaunchAgents/#{identifier}.plist") \
            || ::File.exists?("/Library/LaunchDaemons/#{identifier}.plist")
            notifies :disable, "launchd[#{identifier}]", :immediately
          end
        end
      end
    end

    launchd label(node['cpe_umad']['la_identifier']) do
      action :nothing
      type 'agent'
    end

    launchd label(node['cpe_umad']['ld_dep_identifier']) do
      action :nothing
      type 'daemon'
    end

    launchd label(node['cpe_umad']['ld_nag_identifier']) do
      action :nothing
      type 'daemon'
    end

    # Delete old UMAD directory
    directory '/Library/Application Support/umad' do
      action :delete
      recursive true
    end
  end

  def remove
    # Delete old UMAD directory
    directory '/Library/Application Support/umad' do
      action :delete
      recursive true
    end

    # Delete UMAD directory
    directory '/Library/umad' do
      action :delete
      recursive true
    end

    # Delete Launch Agent
    launchd node['cpe_umad']['la_identifier'] do
      action :delete
      type 'agent'
    end

    # Delete Launch Daemon (Check DEP Record)
    launchd node['cpe_umad']['ld_dep_identifier'] do
      action :delete
      type 'daemon'
    end

    # Delete Launch Daemon (Trigger Nag)
    launchd node['cpe_umad']['ld_nag_identifier'] do
      action :delete
      type 'daemon'
    end
  end
end
