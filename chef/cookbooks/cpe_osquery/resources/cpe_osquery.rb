# Cookbook:: cpe_osquery
#
# Resources:: cpe_osquery
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

  def base_bin_path
    node['cpe_osquery']['base_bin_path']
  end

  def official_pack_list
    [
      'hardware-monitoring',
      'incident-response',
      'it-compliance',
      'osquery-monitoring',
      'ossec-rootkit',
      'osx-attacks',
      'unwanted-chrome-extensions',
      'vuln-management',
      'windows-attacks',
      'windows-hardening',
    ]
  end

  def install
    debian_install if debian?
    macos_install if macos?
    windows_install if windows?
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

  def macos_osquery_file_integrity_healthy?
    healthy = true
    if Gem::Version.new(pkg_version) >= Gem::Version.new('5.0.1')
      files_to_check = %w[
        /opt/osquery/lib/osquery.app/Contents/MacOS/osqueryd
        /opt/osquery/lib/osquery.app/Contents/Resources/osqueryctl
      ]
    elsif Gem::Version.new(pkg_version) == Gem::Version.new('4.9.0.1')
      files_to_check = %w[
        /opt/osquery/osqueryctl
        /opt/osquery/osqueryd
      ]
    else
      files_to_check = %w[
        /usr/local/bin/osqueryctl
        /usr/local/bin/osqueryd
      ]
    end
    files_to_check.each do |cs_file|
      unless ::File.exists?(cs_file)
        healthy = false
      end
    end
    healthy
  end

  def macos_install
    ld_label = 'com.facebook.osqueryd'
    receipt = osquery_pkg['receipt']

    # Force a re-install of osquery if files are missing
    execute "/usr/sbin/pkgutil --forget #{receipt}" do
      not_if { macos_osquery_file_integrity_healthy? }
      not_if { shell_out("/usr/sbin/pkgutil --pkg-info #{receipt}").error? }
      notifies :disable, "launchd[#{ld_label}]", :immediately
    end

    cpe_remote_pkg 'osquery' do
      app pkg_name
      version pkg_version
      checksum pkg_checksum
      receipt receipt
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

  def service_info
    # Set service/daemon information so we can trigger restarts cross platform
    value_for_platform_family(
      'mac_os_x' => { 'launchd' => 'com.facebook.osqueryd' },
      'debian' => { 'service' => 'osqueryd.service' },
      'windows' => { 'service' => 'osqueryd' },
      'default' => nil,
    )
  end

  def manage
    ## TODO: - Manage configs on disk as well as flag files.
    ## Not everyone will have a TLS server for query scheduling
    # file paths
    # yara
    # prometheus_targets
    # views
    # decorators

    # Make sure directory exists and permissions are correct
    directory osquery_dir do
      if macos? || debian?
        owner root_owner
        group node['root_group']
        mode '0700'
      end
    end

    service_type, service_name = service_info.first
    # We need to make this mutable to inject values into it for extensions
    options = node['cpe_osquery']['options'].to_hash

    ext_file = ::File.join(osquery_dir, 'extensions.load')
    extensions = node['cpe_osquery']['extensions']
    extension_paths = []
    unless extensions.empty?
      options['extensions_autoload'] = ext_file
      directory osquery_ext_dir do
        recursive true
        unless windows?
          mode '0755'
          owner root_owner
          group node['root_group']
        end
      end
      extensions.each do |name, values|
        ext_extension = windows? ? 'exe' : 'ext'
        ext_path = ::File.join(osquery_ext_dir, "#{name}.#{ext_extension}")
        extension_paths << ext_path
        cpe_remote_file "#{name}-#{values['version']}" do
          file_name "#{name}-#{values['version']}"
          folder_name "osquery/extensions/#{node['platform_family']}"
          checksum values['checksum']
          path ext_path
          unless windows?
            mode '0755'
            owner root_owner
            group node['root_group']
          end
          notifies :restart, "#{service_type}[#{service_name}]"
        end
      end
      template ext_file do
        source 'extensions.load.erb'
        variables(
          'extensions' => extension_paths,
        )
        notifies :restart, "#{service_type}[#{service_name}]"
      end
    end

    # Lay down config via osquery flags file
    flag_file = ::File.join(osquery_dir, 'osquery.flags')
    template flag_file do
      source 'osquery.flags.erb'
      variables(
        'options' => options,
      )
      not_if { options.nil? }
      notifies :restart, "#{service_type}[#{service_name}]"
    end

    # We need to make this mutable to inject values into it for query packs
    conf = node['cpe_osquery']['conf'].to_hash

    packs = node['cpe_osquery']['packs']
    packs_dir = ::File.join(osquery_dir, 'packs')
    managed_packs = []

    unless packs.empty?
      # Create initial packs directory
      directory packs_dir do
        if macos? || debian?
          owner root_owner
          group node['root_group']
          mode '0755'
        end
      end

      # Inject an empty hash into conf so in the for loop below we can inject the name/paths
      conf['packs'] = {}

      # Loop through the packs, lay them down and add to the conf file
      packs.each do |name, values|
        pack_path = ::File.join(packs_dir, "#{name}.conf")
        conf['packs'][name] = pack_path
        managed_packs.push(pack_path)
        file pack_path do
          if macos? || debian?
            owner root_owner
            group node['root_group']
            mode '0644'
          end
          content Chef::JSONCompat.to_json_pretty(values)
          notifies :restart, "#{service_type}[#{service_name}]"
        end
      end
    end

    # Support the official packs that come from osquery pkg
    official_packs_to_install = node['cpe_osquery']['official_packs_install_list']
    if node['cpe_osquery']['manage_official_packs'] && !official_packs_to_install.empty?
      official_pack_list.each do |name|
        if official_packs_to_install.include?(name)
          pack_path = ::File.join(packs_dir, "#{name}.conf")
          conf['packs'][name] = pack_path
          managed_packs.push(pack_path)
          cookbook_file pack_path do
            source "packs/#{name}.conf"
            if macos? || debian?
              owner root_owner
              group node['root_group']
              mode '0644'
            end
            notifies :restart, "#{service_type}[#{service_name}]"
          end
        end
      end
    end

    conf_path = ::File.join(osquery_dir, 'osquery.conf')

    # Cleanup the packs before updating the conf file
    cleanup_packs(managed_packs, conf_path)

    # Sort all hash sub keys. This is so something like "select config_hash from osquery_info;"
    # can return consistant hash results across devices
    sortedconf = {}
    conf.each do |k, v|
      if v.is_a?(Hash)
        sortedconf[k] = v.sort.to_h
      else
        sortedconf[k] = v
      end
    end

    # Lay down conf file
    unless sortedconf.empty?
      file conf_path do
        if macos? || debian?
          owner root_owner
          group node['root_group']
          mode '0700'
        end
        content Chef::JSONCompat.to_json_pretty(sortedconf.sort.to_h)
        notifies :restart, "#{service_type}[#{service_name}]"
      end
    end

    if windows?
      service 'osqueryd' do
        action :nothing
      end
    end

    debian_manage_service if debian?
    macos_manage_service(flag_file) if macos?
    windows_manage_service if windows?
  end

  def debian_manage_service
    # Ensure osqueryd is running
    service_type, service_name = service_info.first
    template '/etc/default/osqueryd' do
      source 'osqueryd.erb'
      notifies :restart, "#{service_type}[#{service_name}]"
    end
    template '/usr/lib/systemd/system/osqueryd.service' do
      source 'osqueryd.service.systemd.erb'
      notifies :restart, "#{service_type}[#{service_name}]"
    end
    service service_name do
      action :start
    end
  end

  def macos_manage_service(flag_file)
    launchd 'com.facebook.osqueryd' do
      program_arguments [
        ::File.join(base_bin_path, 'osqueryd'),
        '--flagfile',
        flag_file,
      ]
      environment_variables({ 'SYSTEM_VERSION_COMPAT' => '0' }) unless node.os_at_least_or_lower?('10.15.99')
      keep_alive true
      run_at_load true
      throttle_interval 60
      action :enable
    end
  end

  def windows_manage_service
    service 'enforce osqueryd service' do
      action :start
      not_if { osquery_service_status&.include?('Running') }
      service_name 'osqueryd' # Use the service name to avoid namespace collision
    end
  end

  def osquery_service_status
    return nil unless windows?

    status = powershell_out('(Get-Service osqueryd).status').stdout.to_s.chomp
    status.empty? ? nil : status
  end

  def uninstall
    debian_uninstall if debian?
    macos_uninstall if macos?
    windows_uninstall if windows?
  end

  def debian_uninstall
    # Ensure osqueryd is stopped
    service service_info.first[1] do
      action :stop
    end
    # Purge all traces of the package
    dpkg_package 'osquery' do
      action :purge
    end
    # Clean up osquery directories the purge doesn't handle
    %w[
      /etc/osquery
      /opt/osquery
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

    # Clean up osquery files the purge may not always clean up
    %w[
      /etc/default/osqueryd
      /usr/lib/systemd/system/osqueryd.service
    ].each do |osquery_file|
      file osquery_file do
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
    [
      ::File.join(base_bin_path, 'osqueryctl'),
      ::File.join(base_bin_path, 'osqueryd'),
      '/etc/newsyslog.d/com.facebook.osqueryd.conf',
    ].each do |osquery_file|
      file osquery_file do
        action :delete
      end
    end
    # osqueryi is a sometimes a link and sometimes a file
    osqueryi = ::File.join(base_bin_path, 'osqueryi')
    if ::File.symlink?(osqueryi)
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
      /opt/osquery
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

  def cleanup_packs(managed_packs, conf_path)
    # Parse the osquery conf and see which packs are managed
    if ::File.exists?(conf_path)
      configured_packs = Chef::JSONCompat.parse(::File.read(conf_path))['packs']
    else
      Chef::Log.warn('cpe_osquery cannot find conf file')
      return
    end

    # Loop through the configured packs
    configured_packs.each_value do |value|
      # If file is not in our new list of items to manage, we need to delete it
      unless managed_packs.include?(value)
        file value do
          action :delete
        end
      end
    end

    # Loop through official packs and remove ones not being managed via chef
    official_pack_list.each do |pack|
      pack_path = ::File.join(osquery_dir, 'packs', "#{pack}.conf")
      unless managed_packs.include?(pack_path)
        file pack_path do
          action :delete
        end
      end
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
    node['cpe_osquery']['osquery_dir']
  end

  def osquery_ext_dir
    node['cpe_osquery']['osquery_ext_dir']
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
