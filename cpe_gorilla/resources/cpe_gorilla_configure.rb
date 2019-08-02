#
# Cookbook Name:: cpe_gorilla
# Resources:: cpe_gorilla_configure
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_gorilla_configure
provides :cpe_gorilla_configure, :os => 'windows'
default_action :manage

action :manage do
  install if install? && !uninstall?
  remove if uninstall?
end

action_class do
  def install?
    node['cpe_gorilla']['install']
  end

  def uninstall?
    node['cpe_gorilla']['uninstall']
  end

  def install
    return unless node['cpe_gorilla']['install']

    # Get info about gorilla preferences, rejecting unset values
    gorilla_prefs = node['cpe_gorilla']['preferences'].reject { |_k, v| v.nil? }
    if gorilla_prefs.empty? || gorilla_prefs.nil?
      # Don't install gorilla (for now) if no config is set
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    # Create Gorilla folder
    directory node['cpe_gorilla']['dir'] do
      rights :read, 'Everyone'
      rights :full_control, 'Administrators'
      action :create
    end

    # Install YAML configuration file
    config_yaml = ::File.join(node['cpe_gorilla']['dir'], 'config.yaml')
    file config_yaml do
      rights :read, 'Everyone'
      rights :full_control, 'Administrators'
      content gorilla_prefs.to_yaml
    end

    # Get info about gorilla install, rejecting unset values
    exe_info = node['cpe_gorilla']['exe'].reject { |_k, v| v.nil? }
    if exe_info.empty? || exe_info.nil?
      Chef::Log.warn('gorilla package is not populated, skipping install')
      return
    end

    # Create Gorilla bin folder
    bin_dir = ::File.join(node['cpe_gorilla']['dir'], 'bin')
    directory bin_dir do
      rights :read, 'Everyone'
      rights :full_control, 'Administrators'
      action :create
    end

    gorilla_ps1 = ::File.join(bin_dir, 'gorilla_task_splay.ps1')

    template 'gorilla scheduled task ps1' do
      path gorilla_ps1
      source 'gorilla_task_splay.erb'
    end

    # Download and install the executable
    gorilla_exe = ::File.join(bin_dir, 'gorilla.exe')

    # Save gorilla in your pkg repo as: pkgrepo/gorilla/gorilla-version.exe
    cpe_remote_file node['cpe_gorilla']['exe']['name'] do
      file_name "#{node['cpe_gorilla']['exe']['name']}-"\
        "#{node['cpe_gorilla']['exe']['version']}.exe"
      checksum node['cpe_gorilla']['exe']['checksum']
      path gorilla_exe
    end

    runline = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ' \
      "-NoProfile -ExecutionPolicy Bypass \"#{gorilla_ps1}\""

    # Create a scheduled task to run Gorilla
    windows_task node['cpe_gorilla']['exe']['name'] do
      command runline
      frequency :minute
      frequency_modifier node['cpe_gorilla']['task']['minutes_per_run']
      run_level :highest
    end
  end

  def remove
    # Remove Gorilla files
    directory node['cpe_gorilla']['dir'] do
      action :delete
      recursive true
    end

    windows_task node['cpe_gorilla']['exe']['name'] do
      action :delete
    end
  end
end
