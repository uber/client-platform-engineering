#
# Cookbook Name:: cpe_sal
# Resources:: cpe_sal
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_sal
provides :cpe_sal
default_action :manage

action :manage do
  install
  configure
  manage_plugins
  cleanup
end

action_class do # rubocop:disable Metrics/BlockLength
  def create_sal_folder(dir)
    # Create Sal folder
    if node.windows?
      directory dir do
        rights :read, 'Everyone'
        rights :full_control, 'Administrators'
        action :create
      end
    end
  end

  def install
    return unless node['cpe_sal']['install']
    # Get info about the sal_scripts pkg, rejecting unset values
    pkg_info = node['cpe_sal']['scripts_pkg'].reject { |_k, v| v.nil? }
    if pkg_info.empty? || pkg_info.nil?
      Chef::Log.warn('scripts_pkg is not populated, skipping pkg install')
      return
    end
    macos_install(pkg_info) if node.macos?
    windows_install(pkg_info) if node.windows?
  end

  def macos_install(pkg_info)
    # Install sal_scripts.pkg
    cpe_remote_pkg pkg_info['name'] do
      pkg_url pkg_info['pkg_url'] if pkg_info['pkg_url']
      pkg_name pkg_info['pkg_name'] if pkg_info['pkg_name']
      version pkg_info['version']
      checksum pkg_info['checksum']
      receipt pkg_info['receipt']
    end
  end

  def windows_install(pkg_info)
    # Bail if directory isn't set
    gosal_dir = node['cpe_sal']['gosal_dir']
    if gosal_dir.empty? || gosal_dir.nil?
      Chef::Log.warn('gosal dir is not populated, skipping configuration')
      return
    end

    # Ensure the folder exists and is properly managed
    create_sal_folder(gosal_dir)

    gosal_exe = ::File.join(gosal_dir, 'gosal.exe')
    # Save gosal in your pkg repo as: pkgrepo/name/gosal-version.exe
    cpe_remote_file pkg_info['name'] do
      file_name "#{pkg_info['name']}-#{pkg_info['version']}.exe"
      checksum pkg_info['checksum']
      path gosal_exe
    end
  end

  def configure
    return unless node['cpe_sal']['configure']
    # Get info about sal config, rejecting unset values
    sal_prefs = node['cpe_sal']['config'].reject { |_k, v| v.nil? }
    if sal_prefs.empty? || sal_prefs.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end
    macos_configure(sal_prefs) if node.macos?
    windows_configure(sal_prefs) if node.windows?
  end

  def macos_configure(sal_prefs)
    # Build configuration profile and pass it to cpe_profiles
    prefix = node['cpe_profiles']['prefix']
    organization = node['organization'] ? node['organization'] : 'Uber' # rubocop:disable  Style/UnneededCondition, Metrics/LineLength

    sal_profile = {
      'PayloadIdentifier' => "#{prefix}.sal",
      'PayloadRemovalDisallowed' => true,
      'PayloadScope' => 'System',
      'PayloadType' => 'Configuration',
      'PayloadUUID' => '1c03dd17-d2d7-4a68-be40-f41bea3642a9',
      'PayloadOrganization' => organization,
      'PayloadVersion' => 1,
      'PayloadDisplayName' => 'Sal',
      'PayloadContent' => [],
    }
    sal_profile['PayloadContent'].push(
      'PayloadType' => 'com.github.salopensource.sal',
      'PayloadVersion' => 1,
      'PayloadIdentifier' => "#{prefix}.sal",
      'PayloadUUID' => 'e33adee2-4a19-4e69-a330-461920ec8279',
      'PayloadEnabled' => true,
      'PayloadDisplayName' => 'Sal',
    )
    sal_prefs.each do |k, v|
      sal_profile['PayloadContent'][0][k] = v
    end
    node.default['cpe_profiles']["#{prefix}.sal"] = sal_profile

    # Make sure the launchds are always loaded if present
    CPE::Sal.launchds.each do |d|
      launchd d do
        only_if { ::File.exist?("/Library/LaunchDaemons/#{d}.plist") }
        action :enable
      end
    end
  end

  def windows_configure(sal_prefs)
    # Bail if directory isn't set
    gosal_dir = node['cpe_sal']['gosal_dir']
    if gosal_dir.empty? || gosal_dir.nil?
      Chef::Log.warn('gosal dir is not populated, skipping configuration')
      return
    end

    # Ensure the folder exists and is properly managed
    create_sal_folder(gosal_dir)

    # Install JSON configuration file
    config_json = ::File.join(gosal_dir, 'config.json')
    sal_json_prefs = {
      'key' => sal_prefs['key'],
      'management' => sal_prefs['management'],
      'url' => sal_prefs['ServerURL'],
    }
    file config_json do
      rights :read, 'Everyone'
      rights :full_control, 'Administrators'
      content Chef::JSONCompat.to_json_pretty(sal_json_prefs)
    end

    # Create a scheduled task to run gosal
    gosal_exe = ::File.join(gosal_dir, 'gosal.exe')
    windows_task node['cpe_sal']['scripts_pkg']['name'] do
      command "#{gosal_exe} --config #{config_json}"
      frequency :minute
      frequency_modifier node['cpe_sal']['task']['minutes_per_run']
      if Chef::Version.new(Chef::VERSION).major >= 14
        random_delay node['cpe_sal']['task']['seconds_random_delay'] \
        unless node['cpe_sal']['task']['seconds_random_delay'].nil?
      else
        Chef::Log.warn('windows_task is not idempotent with random_delay in '\
          'earlier chef versions.')
      end
      run_level :highest
    end
  end

  def manage_plugins
    return unless node['cpe_sal']['manage_plugins']
    macos_plugins if node.macos?
  end

  def macos_plugins
    # Get plugins dir from cpe_sal library
    plugins_dir = CPE::Sal.plugins_dir
    plugins = node['cpe_sal']['plugins'].reject { |_k, v| v.nil? }
    if plugins.empty? && plugins.empty?
      Chef::Log.warn('plugins is not populated, skipping plugins install')
      return
    end

    plugins.each do |name, script|
      directory "#{plugins_dir}/#{name}_chef" do
        owner 'root'
        group 'wheel'
        mode '0755'
      end

      cookbook_file "#{plugins_dir}/#{name}_chef/#{script}" do
        source script
        owner 'root'
        group 'wheel'
        mode '0750'
      end
    end
  end

  def cleanup
    macos_cleanup if node.macos?
  end

  def macos_cleanup
    # Get plugins dir and currently installed plugins list from cpe_sal library
    plugins_dir = CPE::Sal.plugins_dir
    if ::File.exist?(plugins_dir)
      existing_plugins = CPE::Sal.existing_plugins
      plugins = node['cpe_sal']['plugins'].reject { |_k, v| v.nil? }
      # If plugin directory exists on disk, but isn't managed, remove it.
      existing_plugins.each do |plugin|
        existing_plugin = plugin.split('_')[0]
        unless plugins.key?(existing_plugin)
          directory "#{plugins_dir}/#{existing_plugin}_chef" do
            recursive true
            action :delete
          end
        end
      end
    end

    unless node['cpe_sal']['configure']
      CPE::Sal.launchds.each do |d|
        launchd d do
          only_if { ::File.exist?("/Library/LaunchDaemons/#{d}.plist") }
          action :disable
        end
      end
    end
  end
end
