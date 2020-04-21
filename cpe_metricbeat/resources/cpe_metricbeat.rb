#
# Cookbook Name:: cpe_metricbeat
# Resources:: cpe_metricbeat
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_metricbeat
provides :cpe_metricbeat
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
    pf = node['platform_family']
    zip_info = node['cpe_metricbeat']['zip_info'][pf].reject { |_k, v| v.nil? }
    return if zip_info.nil? || zip_info.empty?

    zip_name = value_for_platform_family(
      'mac_os_x' => "metricbeat-#{zip_info['version']}-darwin-x86_64.zip",
      'debian' => "metricbeat-#{zip_info['version']}-linux-x86_64.zip",
      'windows' => "metricbeat-#{zip_info['version']}-windows-x86_64.zip",
      'default' => nil,
    )
    metricbeat_dir = node['cpe_metricbeat']['dir']
    directory metricbeat_dir do
      recursive true
      owner root_owner
      group root_group
    end
    cpe_remote_zip 'metricbeat_zip' do
      zip_name zip_name
      zip_checksum zip_info['checksum']
      folder_name 'metricbeat'
      extract_location metricbeat_dir
    end
  end

  def configure
    # Get info about metricbeat config, rejecting unset values
    metricbeat_conf = node['cpe_metricbeat']['config'].to_h.reject { |_k, v| v.nil? }
    if metricbeat_conf.empty? || metricbeat_conf.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    metricbeat_dir = node['cpe_metricbeat']['dir']
    directory metricbeat_dir do
      recursive true
      owner root_owner
      group root_group
    end

    setup_macos_service if node.macos?
    setup_debian_service if node.debian_family?

    prefix = node['cpe_launchd']['prefix'] || 'com.uber.chef'
    service_info = value_for_platform_family(
      'mac_os_x' => { 'launchd' => "#{prefix}.metricbeat" },
      'debian' => { 'systemd_unit' => 'metricbeat.service' },
      'windows' => { 'windows_service' => 'metricbeat' },
      'default' => nil,
    )
    service_type, service_name = service_info.first
    # Make a fake service to notify for macOS since we are using cpe_launchd
    if node.macos?
      launchd service_name do
        action :nothing
        only_if { ::File.exist?("/Library/LaunchDaemons/#{service_name}.plist") }
        subscribes :restart, 'cpe_remote_zip[metricbeat_zip]'
      end
    end
    config = ::File.join(metricbeat_dir, 'metricbeat.chef.yml')
    file config do
      owner root_owner
      group root_group
      content metricbeat_conf.to_yaml
      notifies :restart, "#{service_type}[#{service_name}]"
    end
    # Because windows services are annoying and start immediately, so this
    # must come after the config is place
    setup_windows_service if node.windows?
  end

  def setup_windows_service
    metricbeat_dir = node['cpe_metricbeat']['dir']
    exe_path = ::File.join(metricbeat_dir, 'metricbeat.exe')
    bin_path = "#{exe_path}" \
      " -c #{metricbeat_dir}\\metricbeat.chef.yml"
    windows_service 'metricbeat' do
      action %i[create start]
      binary_path_name bin_path
      startup_type :automatic
      delayed_start true
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
    cleanup_debian if node.debian_family?
    cleanup_windows if node.windows?

    directory node['cpe_metricbeat']['dir'] do
      action :delete
      recursive true
    end
  end
end
