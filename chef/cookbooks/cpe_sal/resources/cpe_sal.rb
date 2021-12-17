#
# Cookbook:: cpe_sal
# Resources:: cpe_sal
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

resource_name :cpe_sal
provides :cpe_sal, :os => ['darwin', 'windows']

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
    if windows?
      directory dir do
        action :create
        group node['root_group']
        owner root_owner
      end
    end
  end

  def install
    return unless node['cpe_sal']['install']

    # Get info about the sal_scripts pkg, rejecting unset values
    pkg_info = node['cpe_sal']['scripts_pkg'].compact
    if pkg_info.empty? || pkg_info.nil?
      Chef::Log.warn('scripts_pkg is not populated, skipping pkg install')
      return
    end
    macos_install(pkg_info) if macos?
    windows_install(pkg_info) if windows?
  end

  def macos_install(pkg_info)
    # Install sal_scripts.pkg
    cpe_remote_pkg pkg_info['name'] do
      checksum pkg_info['checksum']
      pkg_url pkg_info['pkg_url'] if pkg_info['pkg_url']
      pkg_name pkg_info['pkg_name'] if pkg_info['pkg_name']
      receipt pkg_info['receipt']
      version pkg_info['version']
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

    # Save gosal in your pkg repo as: pkgrepo/name/gosal-version.exe
    gosal_exe = ::File.join(gosal_dir, 'gosal.exe')
    # Defining owner/group properties here causes this to be non-idempotent
    cpe_remote_file pkg_info['name'] do
      checksum pkg_info['checksum']
      file_name "#{pkg_info['name']}-#{pkg_info['version']}.exe"
      mode '0644'
      path gosal_exe
    end
  end

  def configure
    return unless node['cpe_sal']['configure']

    # Get info about sal config, rejecting unset values
    sal_prefs = node['cpe_sal']['config'].compact
    if sal_prefs.empty? || sal_prefs.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end
    macos_configure(sal_prefs) if macos?
    windows_configure(sal_prefs) if windows?
  end

  def macos_configure(sal_prefs)
    # Build configuration profile and pass it to cpe_profiles
    prefix = node['cpe_profiles']['prefix']
    organization = node['organization'] ? node['organization'] : 'Uber' # rubocop:disable Style/UnneededCondition

    if node.os_at_least_or_lower?('10.15.99')
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
    else
      # Profiles are dead on macOS Big sur and later, so use defaults write
      sal_prefs.each_key do |key|
        next if sal_prefs[key].nil?

        if node.at_least_chef14?
          macos_userdefaults "Configure Sal - #{key}" do
            domain '/Library/Preferences/com.github.salopensource.sal'
            key key
            value sal_prefs[key]
          end
        end
      end
    end

    # Make sure the launchds are always loaded if present
    CPE::Sal.launchds.each do |d|
      launchd d do
        action :enable
        only_if { ::File.exist?("/Library/LaunchDaemons/#{d}.plist") }
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
      content Chef::JSONCompat.to_json_pretty(sal_json_prefs)
      group node['root_group']
      owner root_owner
    end

    # Create a scheduled task to run gosal / use template for splay and stop
    # relying on Chef's built in portions for this as it's buggy.
    gosal_ps1 = ::File.join(gosal_dir, 'gosal_task_splay.ps1')

    template 'gosal splay powershell script' do
      path gosal_ps1
      source 'gosal_task_splay.erb'
    end

    ps_cmd = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ' \
      "-NoProfile -ExecutionPolicy Bypass \"#{gosal_ps1}\""

    windows_task node['cpe_sal']['scripts_pkg']['name'] do
      command ps_cmd
      frequency :minute
      frequency_modifier node['cpe_sal']['task']['minutes_per_run']
      run_level :highest
    end
  end

  def manage_plugins
    return unless node['cpe_sal']['manage_plugins']

    macos_plugins if macos?
  end

  def macos_plugins
    # Get plugins dir from cpe_sal library
    plugins_dir = CPE::Sal.plugins_dir
    plugins = node['cpe_sal']['plugins'].compact
    if plugins.empty? && plugins.empty?
      Chef::Log.warn('plugins is not populated, skipping plugins install')
      return
    end

    plugins.each do |name, script|
      directory "#{plugins_dir}/#{name}_chef" do
        group node['root_group']
        mode '0755'
        owner root_owner
      end

      cookbook_file "#{plugins_dir}/#{name}_chef/#{script}" do
        group node['root_group']
        mode '0750'
        owner root_owner
        source script
      end
    end
  end

  def cleanup
    macos_cleanup if macos?
  end

  def macos_cleanup
    # Get plugins dir and currently installed plugins list from cpe_sal library
    plugins_dir = CPE::Sal.plugins_dir
    if ::File.exist?(plugins_dir)
      existing_plugins = CPE::Sal.existing_plugins
      plugins = node['cpe_sal']['plugins'].compact
      # If plugin directory exists on disk, but isn't managed, remove it.
      existing_plugins.each do |plugin|
        existing_plugin = plugin.split('_')[0]
        unless plugins.key?(existing_plugin)
          directory "#{plugins_dir}/#{existing_plugin}_chef" do
            action :delete
            recursive true
          end
        end
      end
    end

    unless node['cpe_sal']['configure']
      CPE::Sal.launchds.each do |d|
        launchd d do
          action :disable
          only_if { ::File.exist?("/Library/LaunchDaemons/#{d}.plist") }
        end
      end
    end
  end
end
