#
# Cookbook:: cpe_metricbeat
# Resources:: cpe_metricbeat
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

resource_name :cpe_metricbeat
provides :cpe_metricbeat, :os => ['darwin', 'linux', 'windows']

default_action :manage

action :manage do
  install if install?
  configure if configure?
  cleanup if !install? && !configure?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    node['cpe_metricbeat']['install']
  end

  def configure?
    node['cpe_metricbeat']['configure']
  end

  def install
    return if pkg_info.nil? || pkg_info.empty? || pkg_name.nil? || pkg_name.empty?

    # Create metricbeat directory
    create_metricbeat_directory
    # Remove older zip archive from cache
    remove_stale_cache unless current_version?
    # Stop and remove the service if we are updating binaries
    remove_metricbeat_service if windows?
    # Download and extract zip archive
    cpe_remote_zip 'metricbeat_zip' do
      zip_name pkg_name
      zip_checksum pkg_info['checksum']
      folder_name 'metricbeat'
      extract_location metricbeat_dir
    end
  end

  def configure
    # Return if no configuration is specified
    if metricbeat_conf.empty? || metricbeat_conf.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    setup_macos_service if macos?
    setup_debian_service if debian?

    prefix = node['cpe_launchd']['prefix'] || 'com.uber.chef'
    service_info = value_for_platform_family(
      'mac_os_x' => { 'launchd' => "#{prefix}.metricbeat" },
      'debian' => { 'systemd_unit' => 'metricbeat.service' },
      'windows' => { 'windows_service' => 'metricbeat' },
      'default' => nil,
    )
    service_type, service_name = service_info.first
    # Make a fake service to notify for macOS since we are using cpe_launchd
    if macos?
      launchd service_name do
        action :nothing
        only_if { ::File.exist?("/Library/LaunchDaemons/#{service_name}.plist") }
        subscribes :restart, 'cpe_remote_zip[metricbeat_zip]'
      end
    end
    config = ::File.join(metricbeat_dir, 'metricbeat.chef.yml')
    file config do
      owner root_owner
      group node['root_group']
      content YAML.dump(metricbeat_conf)
      notifies :restart, "#{service_type}[#{service_name}]"
    end
    # Because windows services are annoying and start immediately, so this
    # must come after the config is placed
    setup_windows_service if windows?
  end

  def setup_windows_service
    bin_path = "#{metricbeat_bin} -c #{metricbeat_dir}\\metricbeat.chef.yml"
    windows_service 'metricbeat' do
      action %i[create start]
      binary_path_name bin_path
      startup_type :automatic
      delayed_start true
      only_if { ::File.exists?(metricbeat_bin) }
    end
  end

  def setup_debian_service
    metricbeat_dir = node['cpe_metricbeat']['dir']
    unit = {
      'Unit' => {
        'Description' =>
         'metricbeat sends log files to Logstash or directly to Elasticsearch.',
        'Documentation' => ['https://www.elastic.co/products/beats/metricbeat'],
        'Wants' => 'network-online.target',
        'After' => 'network-online.target',
      },
      'Service' => {
        'Type' => 'simple',
        'ExecStart' => "#{metricbeat_dir}/metricbeat" \
        " -c #{metricbeat_dir}/metricbeat.chef.yml",
        'Restart' => 'always',
      },
      'Install' => {
        'WantedBy' => 'multi-user.target',
      },
    }
    systemd_unit 'metricbeat.service' do
      content(unit)
      action %i[create start]
      subscribes :restart, 'cpe_remote_zip[metricbeat_zip]'
    end
  end

  def setup_macos_service
    metricbeat_dir = node['cpe_metricbeat']['dir']
    ld = {
      'program_arguments' => [
        "#{metricbeat_dir}/metricbeat",
        '-c',
        "#{metricbeat_dir}/metricbeat.chef.yml",
      ],
      'disabled' => false,
      'run_at_load' => true,
      'keep_alive' => true,
      'type' => 'daemon',
    }
    node.default['cpe_launchd']['metricbeat'] = ld
  end

  def cleanup_windows
    windows_service 'metricbeat' do
      action %i[stop delete]
    end
  end

  def cleanup_debian
    systemd_unit 'metricbeat.service.app' do
      action %i[stop delete]
    end
  end

  def cleanup
    cleanup_debian if debian?
    cleanup_windows if windows?

    directory node['cpe_metricbeat']['dir'] do
      action :delete
      recursive true
    end
  end

  def current_version?
    if metricbeat_exists?
      if macos? || debian?
        return shell_out("#{metricbeat_bin} version").stdout.include?(pkg_info['version'])
      elsif windows?
        powershell_cmd = "(Get-Item #{metricbeat_bin}).VersionInfo.FileVersion"
        return powershell_out(powershell_cmd).stdout.include?(pkg_info['version'])
      end
    end
    return false
  end

  def metricbeat_exists?
    # Check if metricbeat Exist
    Dir.exist?(metricbeat_dir) && ::File.exist?(metricbeat_bin)
  end

  def metricbeat_dir
    node['cpe_metricbeat']['dir']
  end

  def metricbeat_bin
    ::File.join(metricbeat_dir, node['cpe_metricbeat']['bin'])
  end

  def metricbeat_conf
    node['cpe_metricbeat']['config'].to_h.compact
  end

  def pkg_info
    pf = node['platform_family']
    node['cpe_metricbeat']['zip_info'][pf].compact.reject { |_k, v| v.nil? }
  end

  def pkg_name
    value_for_platform_family(
      'mac_os_x' => "metricbeat-#{pkg_info['version']}-darwin-x86_64.zip",
      'debian' => "metricbeat-#{pkg_info['version']}-linux-x86_64.zip",
      'windows' => "metricbeat-#{pkg_info['version']}-windows-x86_64.zip",
      'default' => nil,
    )
  end

  def create_metricbeat_directory
    directory metricbeat_dir do
      recursive true
      owner root_owner
      group node['root_group']
    end
  end

  def metricbeat_cache
    if macos? || debian?
      ::File.join(Chef::Config[:file_cache_path], 'remote_zip/opt/metricbeat')
    elsif windows?
      ::File.join(Chef::Config[:file_cache_path], 'remote_zip\\C\\ProgramData\\metricbeat')
    end
  end

  def remove_stale_cache
    directory metricbeat_cache do
      recursive true
      action :delete
      ignore_failure true if windows?
    end
  end

  def remove_metricbeat_service
    windows_service 'metricbeat' do
      action %i[stop delete]
      not_if { current_version? }
    end
  end
end
