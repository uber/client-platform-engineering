#
# Cookbook:: cpe_filebeat
# Resources:: cpe_filebeat
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

resource_name :cpe_filebeat
provides :cpe_filebeat, :os => ['darwin', 'linux', 'windows']

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

  def filebeat_exist?
    # Check if Filebeat Exist
    Dir.exist?(filebeat_dir) && ::File.exist?(filebeat_bin)
  end

  def current_version?
    # False if Filebeat Excutable missing or not latest version
    status = false
    if filebeat_exist?
      if macos? || debian?
        cmd = shell_out('sudo /opt/filebeat/filebeat version').stdout
        status = cmd.include? zip_info['version']
        return status
      elsif windows?
        powershell_cmd = "(Get-Item #{filebeat_bin}).VersionInfo.FileVersion"
        cmd = powershell_out(powershell_cmd).stdout
        status = cmd.include? zip_info['version']
        # Guarding false positive on older filebeat version
        if cmd.nil? || cmd.empty? && zip_info['version'].include?('6.4.2')
          status = true
        end
        return status
      end
    end
    status
  end

  def unix_binary?
    # If filebeat exist but we cant extrapulate version return false
    status = false
    if filebeat_exist?
      cmd = shell_out('sudo /opt/filebeat/filebeat version').stdout
      status = cmd.include? zip_info['version']
      return status
    end
    status
  end

  def install
    zip_info.reject { |_k, v| v.nil? }
    return if zip_info.nil? || zip_info.empty?

    # Delete the fielbeat cache containing any prior versions of filebeat
    directory filebeat_cache do
      recursive true
      action :delete
      not_if { current_version? }
      ignore_failure true if windows?
    end
    # Windows only stop the filebeat service to allow changes to be made
    windows_service 'Filebeat Service' do
      action :stop
      only_if { windows? }
      only_if { !current_version? }
    end
    zip_name = value_for_platform_family(
      'mac_os_x' => "filebeat-#{zip_info['version']}-darwin-x86_64.zip",
      'debian' => "filebeat-#{zip_info['version']}-linux-x86_64.zip",
      'windows' => "filebeat-#{zip_info['version']}-windows-x86_64.zip",
      'default' => nil,
    )
    # Create the filebeat directory if it does not exist
    directory filebeat_dir do
      recursive true
      owner root_owner
      group node['root_group']
    end
    # Extract the Filebeat files to the filebeat directory
    cpe_remote_zip 'filebeat_zip' do
      zip_name zip_name
      zip_checksum zip_info['checksum']
      folder_name 'filebeat'
      extract_location filebeat_dir
    end
    # If the filebeat executable is damaged update file properties
    file filebeat_bin do
      mode '0755'
      owner root_owner
      group node['root_group']
      only_if { macos? }
      only_if { !unix_binary? }
    end
  end

  def configure
    # Get info about filebeat config, rejecting unset values
    filebeat_conf = node['cpe_filebeat']['config'].to_h.reject { |_k, v| v.nil? }
    if filebeat_conf.empty? || filebeat_conf.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    directory filebeat_dir do
      recursive true
      owner root_owner
      group node['root_group']
    end

    setup_macos_service if macos?
    setup_debian_service if debian?

    prefix = node['cpe_launchd']['prefix'] || 'com.uber.chef'
    service_info = value_for_platform_family(
      'mac_os_x' => { 'launchd' => "#{prefix}.filebeat" },
      'debian' => { 'systemd_unit' => 'filebeat.service' },
      'windows' => { 'windows_service' => 'Filebeat Service' },
      'default' => nil,
    )
    service_type, service_name = service_info.first
    # Make a fake service to notify for macOS since we are using cpe_launchd
    if macos?
      launchd service_name do
        action :nothing
        only_if { ::File.exist?("/Library/LaunchDaemons/#{service_name}.plist") }
        subscribes :restart, 'cpe_remote_zip[filebeat_zip]'
      end
    end
    config = ::File.join(filebeat_dir, 'filebeat.chef.yml')
    file config do
      owner root_owner
      group node['root_group']
      content YAML.dump(filebeat_conf)
      notifies :restart, "#{service_type}[#{service_name}]"
    end
    # Because windows services are annoying and start immediately, so this
    # must come after the config is placed
    setup_windows_service if windows?
  end

  def setup_windows_service
    exe_path = ::File.join(filebeat_dir, 'filebeat.exe')
    bin_path = "#{exe_path} -c #{filebeat_dir}\\filebeat.chef.yml"
    windows_service 'Filebeat Service' do
      action %i[create start]
      binary_path_name bin_path
      startup_type :automatic
      delayed_start true
      description 'Filebeat sends log files to Logstash or directly to Elasticsearch.'
      only_if { ::File.exists?(exe_path) }
    end
  end

  def setup_debian_service
    file filebeat_bin do
      mode '0755'
    end

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
    cleanup_debian if debian?
    cleanup_windows if windows?

    directory node['cpe_filebeat']['dir'] do
      action :delete
      recursive true
      ignore_failure true if windows?
    end
  end

  def filebeat_dir
    node['cpe_filebeat']['dir']
  end

  def filebeat_bin
    ::File.join(filebeat_dir, node['cpe_filebeat']['bin'])
  end

  def filebeat_cache
    if macos? || debian?
      ::File.join(Chef::Config[:file_cache_path], 'remote_zip/opt/filebeat')
    elsif windows?
      ::File.join(Chef::Config[:file_cache_path], 'remote_zip\\C\\ProgramData\\filebeat')
    end
  end

  def zip_info
    node['cpe_filebeat']['zip_info'][node['platform_family']]
  end
end
