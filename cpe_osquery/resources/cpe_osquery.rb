#
# Cookbook Name:: cpe_osquery
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
provides :cpe_osquery
default_action :manage

action :manage do
  install if install?
  manage if manage?
  uninstall if !install? && !manage? && uninstall?
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
    # Root preferences for agent and package
    osquery_pkg = node['cpe_osquery']['pkg'].to_hash

    debian_install(osquery_pkg) if node.debian_family?
    macos_install(osquery_pkg) if node.macos?
    windows_install(osquery_pkg) if node.windows?
  end

  def debian_install(osquery_pkg)
    file_name = "#{osquery_pkg['name']}-"\
      "#{osquery_pkg['version']}.deb"
    deb_path = ::File.join(Chef::Config[:file_cache_path], file_name)
    cpe_remote_file osquery_pkg['name'] do
      backup 1
      file_name file_name
      checksum osquery_pkg['checksum']
      path deb_path
    end
    # Install the package
    dpkg_package file_name do
      source deb_path
      version osquery_pkg['dpkg_version']
      action :install
    end
  end

  def macos_install(osquery_pkg)
    # Install it!
    cpe_remote_pkg 'osquery' do
      app osquery_pkg['name']
      version osquery_pkg['version']
      checksum osquery_pkg['checksum']
      receipt osquery_pkg['receipt']
    end
    # Make sure logs get rotated
    syslog_conf = 'com.facebook.osqueryd.conf'
    syslog_conf_path = ::File.join('/etc/newsyslog.d', syslog_conf)
    cookbook_file syslog_conf_path do
      source syslog_conf
    end
  end

  def windows_install(osquery_pkg)
    version = osquery_pkg['version']
    file_name = "#{osquery_pkg['name']}-"\
      "#{version}.nupkg"
    # Cache directory where we will stash the nupkg for osquery
    pkg_dir = ::File.join(Chef::Config[:file_cache_path], 'osquery')
    # Create the directory where the package will live.
    directory pkg_dir
    # Construct the file path to the nupkg so we can place it and install it.
    pkg_path = ::File.join(pkg_dir, file_name)
    cpe_remote_file osquery_pkg['name'] do
      backup 1
      file_name file_name
      checksum osquery_pkg['checksum']
      path pkg_path
    end
    # Install the nupkg
    chocolatey_package 'osquery' do
      source pkg_dir
      options "--checksum #{osquery_pkg['checksum']} --params='/InstallService'"
      action :upgrade
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

    osquery_dir = value_for_platform_family(
      'windows' => 'C:\ProgramData\osquery',
      'debian' => '/etc/osquery',
      'mac_os_x' => '/var/osquery',
      'default' => nil,
    )

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
    options = node['cpe_osquery']['options'].reject { |_k, v| v.nil? }
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
    end
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
    ].each do |osquery_dir|
      directory osquery_dir do
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
      not_if do
        shell_out('/usr/sbin/pkgutil --pkg-info com.facebook.osquery').error?
      end
    end
  end

  def windows_uninstall
    chocolatey_package 'osquery' do
      action :remove
    end
  end
end
