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

resource_name :cpe_umad_install
provides :cpe_umad_install, :os => 'darwin'
default_action :manage

action :manage do
  install if install? && !uninstall?
  remove if uninstall?
end

action_class do
  def custom_resources?
    node['cpe_umad']['custom_resources']
  end

  def install?
    node['cpe_umad']['install']
  end

  def uninstall?
    node['cpe_umad']['uninstall']
  end

  def install
    # Create umad base folders
    [
      '/Library/Application Support/umad',
      '/Library/Application Support/umad/Resources',
      '/Library/Application Support/umad/Resources/umad.nib',
    ].each do |dir|
      directory dir do
        group 'wheel'
        owner 'root'
        mode '0755'
        action :create
      end
    end

    # Create Log folder with 777 permissions so user agent can write to it.
    directory '/Library/Application Support/umad/Logs' do
      group 'wheel'
      owner 'root'
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

    # Install UMAD files
    umad_files.each do |item|
      cookbook_file "/Library/Application Support/umad/Resources/#{item}" do
        owner 'root'
        group 'wheel'
        mode '0755'
        action :create
        path "/Library/Application Support/umad/Resources/#{item}"
        source "resources/#{item}"
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
      cookbook_file "/Library/Application Support/umad/Resources/#{item}" do
        owner 'root'
        group 'wheel'
        mode '0755'
        action :create
        path "/Library/Application Support/umad/Resources/#{item}"
        source "#{source_path}/#{item}"
      end
    end

    # UMAD nib files
    umad_nib_files = [
      'designable.nib',
      'keyedobjects.nib',
    ]

    # Install UMAD nib files
    umad_nib_files.each do |item|
      cookbook_file "/Library/Application Support/umad/Resources/umad.nib/#{item}" do
        owner 'root'
        group 'wheel'
        mode '0755'
        action :create
        path "/Library/Application Support/umad/Resources/umad.nib/#{item}"
        source "umad.nib/#{item}"
      end
    end
  end

  def remove
    # Delete UMAD directory
    directory '/Library/Application Support/umad' do
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
