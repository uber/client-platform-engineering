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
        cmd = shell_out('/opt/filebeat/filebeat version').stdout
        status = cmd.include? zip_info['version']
        return status
      elsif windows?
        cmd = powershell_out("(Get-Item #{filebeat_bin}).VersionInfo.FileVersion").stdout
        status = cmd.include?(zip_info['version'])
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

    # Self-remediation and repair logic
    unhealthy_count = filebeat_unhealthy_count
    reinstall_count = filebeat_reinstall_count
    repair = false

    filebeat_running? ? unhealthy_count = 0 : unhealthy_count += 1
    if unhealthy_count > unhealthy_limit
      unhealthy_count = 0
      reinstall_count += 1
      repair = true
    end

    # Reinstall if service is broken or needs an upgrade
    cleanup if !current_version? || repair

    zip_name = value_for_platform_family(
      'mac_os_x' => "filebeat-#{zip_info['version']}-darwin-x86_64.zip",
      'debian' => "filebeat-#{zip_info['version']}-linux-x86_64.zip",
      'windows' => "filebeat-#{zip_info['version']}-windows-x86_64.zip",
      'default' => nil,
    )
    # Create the filebeat directory if it does not exist
    create_filebeat_directory
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

    # This will track the health history of the Filebeat service
    set_filebeat_health_history(unhealthy_count, reinstall_count)
  end

  def configure
    # Get info about filebeat config, rejecting unset values
    if filebeat_conf.empty? || filebeat_conf.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    # Place certificate if it does not exist
    cookbook_file certificate_path do
      source certificate
      owner root_owner
      group node['root_group']
      mode '0644' unless windows?
      not_if { certificate.nil? }
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

  def create_filebeat_directory
    directory filebeat_dir do
      recursive true
      owner root_owner
      group node['root_group']
    end
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
    # Delete the filebeat cache containing any prior versions of filebeat
    directory filebeat_cache do
      recursive true
      action :delete
      ignore_failure true if windows?
    end

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

  def filebeat_running?
    if windows?
      status = powershell_out('(Get-Service "Filebeat Service" -ErrorAction SilentlyContinue).Status').stdout.to_s.chomp
      node.safe_nil_empty?(status) ? false : status&.include?('Running')
    elsif macos?
      node.daemon_running?('filebeat')
    else
      shell_out('systemctl status filebeat').run_command.stdout.to_s[/Active: active \(running\)/].nil? ? false : true
    end
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

  def filebeat_unhealthy_count
    get_filebeat_health_history['unhealthy_count']
  end

  def filebeat_reinstall_count
    get_filebeat_health_history['reinstall_count']
  end

  def get_filebeat_health_history
    json_path = ::File.join(filebeat_dir, 'cpe_filebeat.json')
    valid = false
    if ::File.exists?(json_path)
      json = node.parse_json(json_path)
      valid = %w(unhealthy_count reinstall_count).all? { |k| json.key?(k) && json[k].is_a?(Integer) }
    end
    valid ? json : { 'unhealthy_count' => 0, 'reinstall_count' => 0 }
  end

  def set_filebeat_health_history(unhealthy = 0, reinstalls = 0)
    json_path = ::File.join(filebeat_dir, 'cpe_filebeat.json')
    history = {
      'unhealthy_count' => unhealthy,
      'reinstall_count' => reinstalls,
    }
    file json_path do
      action :create
      content Chef::JSONCompat.to_json_pretty(history)
    end
  end

  def zip_info
    node['cpe_filebeat']['zip_info'][node['platform_family']]
  end

  def unhealthy_limit
    node['cpe_filebeat']['unhealthy_limit']
  end

  def certificate
    node['cpe_filebeat']['certificate']
  end

  def certificate_path
    ::File.join(node['cpe_filebeat']['dir'], certificate) if certificate
  end

  def filebeat_conf
    node['cpe_filebeat']['config'].to_h.reject { |_k, v| v.nil? }
  end
end
