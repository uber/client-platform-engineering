#
# Cookbook:: cpe_winlogbeat
# Resources:: cpe_winlogbeat
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2022-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_winlogbeat
provides :cpe_winlogbeat, :os => ['windows']

default_action :manage

action :manage do
  install if install?
  configure if configure?
  cleanup if !install? && !configure?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    node['cpe_winlogbeat']['install']
  end

  def configure?
    node['cpe_winlogbeat']['configure']
  end

  def install
    pkg_name = "winlogbeat-#{pkg_info['version']}-windows-x86_64.zip"
    return if pkg_info.nil? || pkg_info.empty? || pkg_name.nil? || pkg_name.empty?

    # Create winlogbeat directory
    create_winlogbeat_directory
    # Remove older zip archive from cache
    remove_stale_cache unless current_version?
    # Stop and remove the service if we are updating binaries
    remove_winlogbeat_service unless current_version?
    # Download and extract zip archive
    cpe_remote_zip 'winlogbeat_zip' do
      zip_name pkg_name
      zip_checksum pkg_info['checksum']
      folder_name 'winlogbeat'
      extract_location winlogbeat_dir
      not_if { winlogbeat_running? }
    end
  end

  def configure
    # Return if no configuration is specified
    if winlogbeat_conf.empty? || winlogbeat_conf.nil?
      Chef::Log.warn('winlogbeat config is not populated, skipping configuration')
      return
    end

    file ::File.join(winlogbeat_dir, 'winlogbeat.chef.yml') do
      owner root_owner
      group node['root_group']
      content YAML.dump(winlogbeat_conf)
      notifies :restart, 'windows_service[winlogbeat]'
    end
    # Because windows services are annoying and start immediately, so this
    # must come after the config is placed
    windows_service 'winlogbeat' do
      action %i[create start]
      binary_path_name "#{winlogbeat_bin} -c #{winlogbeat_dir}\\winlogbeat.chef.yml"
      startup_type :automatic
      delayed_start true
      only_if { ::File.exists?(winlogbeat_bin) }
      timeout 180
    end
  end

  def cleanup
    remove_winlogbeat_service

    directory node['cpe_winlogbeat']['dir'] do
      action :delete
      recursive true
    end
  end

  def current_version?
    if winlogbeat_exists?
      powershell_cmd = "(Get-Item #{winlogbeat_bin}).VersionInfo.FileVersion"
      return powershell_out(powershell_cmd).stdout.include?(pkg_info['version'])

    end
    return false
  end

  def winlogbeat_running?
    if windows?
      status = node.get_local_service_status('winlogbeat', :State)
      node.safe_nil_empty?(status) ? false : status&.include?('Running')
    elsif macos?
      node.daemon_running?('winlogbeat')
    else
      shell_out('systemctl status winlogbeat').run_command.stdout.to_s[/Active: active \(running\)/].nil? ? false : true
    end
  end

  def winlogbeat_exists?
    # Check if winlogbeat Exist
    Dir.exist?(winlogbeat_dir) && ::File.exist?(winlogbeat_bin)
  end

  def winlogbeat_dir
    node['cpe_winlogbeat']['dir']
  end

  def winlogbeat_bin
    ::File.join(winlogbeat_dir, node['cpe_winlogbeat']['bin'])
  end

  def winlogbeat_conf
    node['cpe_winlogbeat']['config'].to_h.compact
  end

  def pkg_info
    node['cpe_winlogbeat']['zip_info'].compact.reject { |_k, v| v.nil? }
  end

  def create_winlogbeat_directory
    directory winlogbeat_dir do
      recursive true
      owner root_owner
      group node['root_group']
    end
  end

  def winlogbeat_cache
    ::File.join(Chef::Config[:file_cache_path], 'remote_zip\\C\\ProgramData\\winlogbeat')
  end

  def remove_stale_cache
    directory winlogbeat_cache do
      recursive true
      action :delete
      ignore_failure true
    end
  end

  def remove_winlogbeat_service
    windows_service 'winlogbeat' do
      action %i[stop delete]
    end
  end
end
