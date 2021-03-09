# Cookbook Name:: cpe_osquery
#
# Resources:: cpe_osquery
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_osquery
provides :cpe_osquery, :os => ['darwin', 'linux', 'windows']

default_action :manage

action :manage do
  install if install?
  manage if manage? && !uninstall?
  uninstall if uninstall? && !install?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    node['cpe_osquery']['install']
  end

  def manage?
    node['cpe_osquery']['manage']
  end

  def uninstall?
    node['cpe_osquery']['uninstall']
  end

  def install
    debian_install if node.debian_family?
    macos_install if node.macos?
    windows_install if node.windows?
  end

  def debian_install
    # Download installer package
    download_package
    # Install the package
    dpkg_package pkg_filename do
      source pkg_filepath
      version osquery_pkg['dpkg_version']
      action :install
    end
  end

  def macos_install
    # Install it!
    ld_label = 'com.facebook.osqueryd'
    cpe_remote_pkg 'osquery' do
      app pkg_name
      version pkg_version
      checksum pkg_checksum
      receipt osquery_pkg['receipt']
      if ::File.exists?("/Library/LaunchDaemons/#{ld_label}.plist")
        notifies :restart, "launchd[#{ld_label}]", :immediately
      end
    end
    # Make sure logs get rotated
    syslog_conf = 'com.facebook.osqueryd.conf'
    syslog_conf_path = ::File.join('/etc/newsyslog.d', syslog_conf)
    cookbook_file syslog_conf_path do
      source syslog_conf
    end
    # Triger launchd restart
    launchd ld_label do
      action :nothing
    end
  end

  def windows_install
    download_package

    # Install the MSI
    windows_package "Install #{pkg_name}" do
      source pkg_filepath
      options '/norestart /passive /qn'
      checksum pkg_checksum
    end
  end

  def manage
    ## ToDo - Manage configs on disk as well as flag files.
    ## Not everyone will have a TLS server for query scheduling
    # schedule
    # packs
    # file paths
    # yara
    # prometheus_targets
    # views
    # decorators

    # Make sure directory exists and permissions are correct
    directory osquery_dir do
      if node.macos? | node.debian?
        owner root_owner
        group root_group
        mode '0700'
      end
    end
    # Set service/daemon information so we can trigger restarts cross platform
    service_info = value_for_platform_family(
      'mac_os_x' => { 'launchd' => 'com.facebook.osqueryd' },
      ## Specify osqueryd for 14, osqueryd.service for 16+
      'debian' => { 'service' => 'osqueryd.service' },
      'windows' => { 'service' => 'osqueryd' },
      'default' => nil,
    )
    # Not sure if there is a better way to do this :(
    if node.ubuntu14?
      service_info = { 'service' => 'osqueryd' }
    end
    service_type, service_name = service_info.first
    flag_file = ::File.join(osquery_dir, 'osquery.flags')
    options = node['cpe_osquery']['options'].compact
    # Lay down config via osquery flags file
    template flag_file do
      source 'osquery.flags.erb'
      variables(
        'options' => options,
      )
      not_if { options.nil? }
      notifies :restart, "#{service_type}[#{service_name}]"
    end
    ext_file = ::File.join(osquery_dir, 'extensions.load')
    extensions = node['cpe_osquery']['extensions'].reject(&:nil?)
    template ext_file do
      source 'extensions.load.erb'
      variables(
        'extensions' => extensions,
      )
      not_if { extensions.nil? }
      notifies :restart, "#{service_type}[#{service_name}]"
    end
    debian_manage_service if node.debian_family?
    macos_manage_service(flag_file) if node.macos?
    windows_manage_service if node.windows?
  end

  def debian_manage_service
    # Ensure osqueryd is running
    if node.ubuntu14?
      cookbook_file '/etc/init.d/osqueryd' do
        source 'osqueryd.init'
        mode '0755'
      end
      service 'osqueryd' do
        action :start
      end
    else
      cookbook_file '/usr/lib/systemd/system/osqueryd.service' do
        source 'osqueryd.service.systemd'
      end
      service 'osqueryd.service' do
        action :start
      end
    end
  end

  def macos_manage_service(flag_file)
    launchd 'com.facebook.osqueryd' do
      program_arguments [
        '/usr/local/bin/osqueryd',
        '--flagfile',
        flag_file,
      ]
      keep_alive true
      run_at_load true
      throttle_interval 60
      action :enable
    end
  end

  def windows_manage_service
    service 'osqueryd' do
      action :start
      not_if { osquery_service_status&.include?('Running') }
    end
  end

  def osquery_service_status
    return nil unless node.windows?
    status = powershell_out('(Get-Service osqueryd).status').stdout.to_s.chomp
    status.empty? ? nil : status
  end

  def uninstall
    debian_uninstall if node.debian_family?
    macos_uninstall if node.macos?
    windows_uninstall if node.windows?
  end

  def debian_uninstall
    # Ensure osqueryd is stopped
    service 'osqueryd.service' do
      action :stop
    end
    # Purge all traces of the package
    dpkg_package 'osquery' do
      action :purge
    end
    # Clean up osquery directories the purge doesn't handle
    %w[
      /etc/osquery
      /usr/lib/osquery/
      /usr/share/osquery
      /var/osquery
      /var/log/osquery
    ].each do |osquery_directory|
      directory osquery_directory do
        recursive true
        action :delete
      end
    end
  end

  def macos_uninstall
    # Clean up the launch daemon
    launchd 'com.facebook.osqueryd' do
      action :delete
    end
    # Clean up osquery files
    %w[
      /usr/local/bin/osqueryctl
      /usr/local/bin/osqueryd
      /etc/newsyslog.d/com.facebook.osqueryd.conf
    ].each do |osquery_file|
      file osquery_file do
        action :delete
      end
    end
    # osqueryi is a sometimes a link and sometimes a file
    osqueryi = '/usr/local/bin/osqueryi'
    if ::File.symlink?('/usr/local/bin/osqueryi')
      link osqueryi do
        action :delete
      end
    else
      file osqueryi do
        action :delete
      end
    end
    # Clean up osquery directories
    %w[
      /var/osquery
      /var/log/osquery
    ].each do |osquery_dir|
      directory osquery_dir do
        recursive true
        action :delete
      end
    end
    execute '/usr/sbin/pkgutil --forget com.facebook.osquery' do
      not_if { shell_out('/usr/sbin/pkgutil --pkg-info com.facebook.osquery').error? }
    end
  end

  def windows_uninstall
    # Only download if we need to uninstall
    download_package if node['packages'].key?(pkg_name)

    # Invoke MSI uninstall
    windows_package "uninstall #{pkg_name}" do
      source pkg_filepath
      checksum pkg_checksum
      action :remove
      options '/qn /norestart'
      only_if { node['packages'].key?(pkg_name) && ::File.exists?(pkg_filepath) }
    end
    # Run custom script to force cleanup of remaining files
    powershell_script 'uninstall osquery - force cleanup' do
      code <<-PSCRIPT
      $serviceName = 'osqueryd'
      $serviceDescription = 'osquery daemon service'
      $progFiles = [System.Environment]::GetEnvironmentVariable('ProgramFiles')
      $targetFolder = Join-Path $progFiles 'osquery'
      # Remove the osquery path from the System PATH variable. Note: Here
      # we don't make use of our local vars, as Regex requires escaping the '\'
      $oldPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
      if ($oldPath -imatch [regex]::escape($targetFolder)) {
        $newPath = $oldPath -replace [regex]::escape($targetFolder), $NULL
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
      }
      if ((Get-Service $serviceName -ErrorAction SilentlyContinue)) {
        Stop-Service $serviceName
        # If we find zombie processes, ensure they're termintated
        $proc = Get-Process | Where-Object { $_.ProcessName -eq 'osqueryd' }
        if ($null -ne $proc) {
          Stop-Process -Force $proc -ErrorAction SilentlyContinue
        }
        Set-Service $serviceName -startuptype 'manual'
        Get-CimInstance -ClassName Win32_Service -Filter "Name='osqueryd'" | Invoke-CimMethod -methodName Delete
      }
      if (Test-Path $targetFolder) {
        Remove-Item -Force -Recurse $targetFolder
      } else {
        Write-Debug 'osquery was not found on the system. Nothing to do.'
      }
      PSCRIPT
      only_if { ::File.directory?(::File.join(ENV['ProgramFiles'], 'osquery')) }
    end
  end

  def osquery_pkg
    node['cpe_osquery']['pkg'].to_hash
  end

  def pkg_version
    osquery_pkg['version']
  end

  def pkg_name
    osquery_pkg['name']
  end

  def pkg_checksum
    osquery_pkg['checksum']
  end

  def osquery_dir
    value_for_platform_family(
      'windows' => 'C:\Program Files\osquery',
      'debian' => '/etc/osquery',
      'mac_os_x' => '/var/osquery',
      'default' => nil,
    )
  end

  def pkg_filename
    filetype = value_for_platform_family(
      'windows' => 'msi',
      'debian' => 'deb',
      'mac_os_x' => 'pkg',
      'default' => nil,
    )
    "#{pkg_name}-#{pkg_version}.#{filetype}"
  end

  def pkg_filepath
    ::File.join(Chef::Config[:file_cache_path], pkg_filename)
  end

  def download_package
    cpe_remote_file pkg_name do
      backup 1
      file_name pkg_filename
      checksum pkg_checksum
      path pkg_filepath
    end
  end
end
