#
# Cookbook Name:: cpe_filebeat
# Resources:: cpe_filebeat
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_filebeat
provides :cpe_filebeat
default_action :manage

action :manage do
  install if install?
  configure if configure?
  cleanup if !install? && !configure?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    node['cpe_filebeat']['install']
  end

  def configure?
    node['cpe_filebeat']['configure']
  end

  def install
    pf = node['platform_family']
    zip_info = node['cpe_filebeat']['zip_info'][pf].reject { |_k, v| v.nil? }
    return if zip_info.nil? || zip_info.empty?

    zip_name = value_for_platform_family(
      'mac_os_x' => "filebeat-#{zip_info['version']}-darwin-x86_64.zip",
      'debian' => "filebeat-#{zip_info['version']}-linux-x86_64.zip",
      'windows' => "filebeat-#{zip_info['version']}-windows-x86_64.zip",
      'default' => nil,
    )
    filebeat_dir = node['cpe_filebeat']['dir']
    directory filebeat_dir do
      recursive true
      owner root_owner
      group root_group
    end
    cpe_remote_zip 'filebeat_zip' do
      zip_name zip_name
      zip_checksum zip_info['checksum']
      folder_name 'filebeat'
      extract_location filebeat_dir
    end
  end

  def configure
    # Get info about filebeat config, rejecting unset values
    filebeat_conf = node['cpe_filebeat']['config'].to_h.reject { |_k, v| v.nil? }
    if filebeat_conf.empty? || filebeat_conf.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    filebeat_dir = node['cpe_filebeat']['dir']
    directory filebeat_dir do
      recursive true
      owner root_owner
      group root_group
    end

    setup_macos_service if node.macos?
    setup_debian_service if node.debian_family?

    prefix = node['cpe_launchd']['prefix'] || 'com.uber.chef'
    service_info = value_for_platform_family(
      'mac_os_x' => { 'launchd' => "#{prefix}.filebeat" },
      'debian' => { 'systemd_unit' => 'filebeat.service' },
      'windows' => { 'windows_service' => 'Filebeat Service' },
      'default' => nil,
    )
    service_type, service_name = service_info.first
    # Make a fake service to notify for macOS since we are using cpe_launchd
    if node.macos?
      launchd service_name do
        action :nothing
        only_if do
          ::File.exist?("/Library/LaunchDaemons/#{service_name}.plist")
        end
        subscribes :restart, 'cpe_remote_zip[filebeat_zip]'
      end
    end
    config = ::File.join(filebeat_dir, 'filebeat.chef.yml')
    file config do
      owner root_owner
      group root_group
      content filebeat_conf.to_yaml
      notifies :restart, "#{service_type}[#{service_name}]"
    end
    # Because windows services are annoying and start immediately, so this
    # must come after the config is placed
    setup_windows_service if node.windows?
  end

  def setup_windows_service
    filebeat_dir = node['cpe_filebeat']['dir']
    exe_path = ::File.join(filebeat_dir, 'filebeat.exe')
    bin_path = "#{exe_path}" \
      " -c #{filebeat_dir}\\filebeat.chef.yml"
    windows_service 'Filebeat Service' do
      action %i[create start]
      binary_path_name bin_path
      startup_type :automatic
      delayed_start true
      description 'Filebeat sends log files to Logstash or directly to Elasticsearch.'
    end
  end

  def setup_debian_service
    filebeat_dir = node['cpe_filebeat']['dir']
    unit = {
      'Unit' => {
        'Description' =>
         'Filebeat sends log files to Logstash or directly to Elasticsearch.',
        'Documentation' => ['https://www.elastic.co/products/beats/filebeat'],
        'Wants' => 'network-online.target',
        'After' => 'network-online.target',
      },
      'Service' => {
        'Type' => 'simple',
        'ExecStart' => "#{filebeat_dir}/filebeat" \
        " -c #{filebeat_dir}/filebeat.chef.yml" \
        ' -path.logs /var/log/filebeat',
        'Restart' => 'always',
      },
      'Install' => {
        'WantedBy' => 'multi-user.target',
      },
    }
    systemd_unit 'filebeat.service' do
      content(unit)
      action %i[create start]
      subscribes :restart, 'cpe_remote_zip[filebeat_zip]'
    end
  end

  def setup_macos_service
    filebeat_dir = node['cpe_filebeat']['dir']
    ld = {
      'program_arguments' => [
        "#{filebeat_dir}/filebeat",
        '-c',
        "#{filebeat_dir}/filebeat.chef.yml",
      ],
      'disabled' => false,
      'run_at_load' => true,
      'keep_alive' => true,
      'type' => 'daemon',
    }
    node.default['cpe_launchd']['filebeat'] = ld
  end

  def cleanup_windows
    windows_service 'Filebeat Service' do
      action %i[stop delete]
    end
  end

  def cleanup_debian
    systemd_unit 'filebeat.service.app' do
      action %i[stop delete]
    end
  end

  def cleanup
    cleanup_debian if node.debian_family?
    cleanup_windows if node.windows?

    directory node['cpe_filebeat']['dir'] do
      action :delete
      recursive true
      ignore_failure true if node.windows?
    end
  end
end
