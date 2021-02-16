#
# Cookbook Name:: cpe_anyconnect
# Resources:: cpe_anyconnect
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2021-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_anyconnect
provides :cpe_anyconnect, :os => ['darwin', 'windows']

default_action :manage

action :manage do
  manage if manage?
  install if install?
  uninstall if !install? && uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    node['cpe_anyconnect']['install']
  end

  def manage?
    node['cpe_anyconnect']['manage']
  end

  def uninstall?
    node['cpe_anyconnect']['uninstall']
  end

  def install
    debian_install if node.debian_family?
    macos_install if node.macos?
    windows_install if node.windows?
  end

  def debian_install
    # TODO: need to write
    return
  end

  def macos_install
    # Create the cache directories and stage necessary files
    create_anyconnect_cache
    sync_anyconnect_cache
    # package properties
    pkg = node['cpe_anyconnect']['pkg']

    # cpe_remote_pkg doesn't support ChoiceChanges.xml which is needed to not install specific parts of this package
    # Download the anyconnect pkg
    download_package(pkg)

    # Install the pacakge with the ChoiceChangesXML
    cc_xml_path = ::File.join(anyconnect_root_cache_path, 'pkg', 'ChoiceChanges.xml')
    allow_downgrade = pkg['allow_downgrade']
    if allow_downgrade
      Chef::Log.warn('cpe_anyconnect - AnyConnect package has logic to fail if attempting to downgrade - you must '\
        'uninstall the application first!')
      Chef::Log.warn('cpe_anyconnect - forcing downgrade to false')
      allow_downgrade = False
    end
    execute "/usr/sbin/installer -applyChoiceChangesXML #{cc_xml_path} -pkg #{pkg_path(pkg)} -target /" do
      # functionally equivalent to allow_downgrade false on cpe_remote_pkg
      unless allow_downgrade
        not_if { node.min_package_installed?(pkg['receipt'], pkg['version']) }
      end
      notifies :create, 'file[trigger_gui]', :immediately
    end

    # We only want the UI to trigger upon the first install and upgrades.
    # In testing, their own postinstall script logic is very unreliable.
    # Touch the gui_keepalive path and then restart the agent will trigger the UI
    gui_la_label = node['cpe_anyconnect']['la_gui_identifier']
    file 'trigger_gui' do
      action :nothing
      only_if { ::File.exist?("/Library/LaunchAgents/#{gui_la_label}.plist") }
      path '/opt/cisco/anyconnect/gui_keepalive'
      notifies :restart, "launchd[#{gui_la_label}]", :immediately
    end

    launchd gui_la_label do
      type 'agent'
      action :nothing
    end
  end

  def windows_install
    # Create the cache directories and stage necessary files
    create_anyconnect_cache
    sync_anyconnect_cache

    # Download and Install all modules
    node['cpe_anyconnect']['modules'].each do |pkg|
      # Download the anyconnect msi
      download_package(pkg)

      # Set default installer arguments
      pkg['install_args'].nil? ? install_args = '/norestart /passive /qn' :
        install_args = "/norestart /passive /qn #{pkg['install_args']}"

      # Install the pacakge
      windows_package "Install #{pkg['display_name']}" do
        source pkg_path(pkg)
        options install_args
        checksum pkg['checksum']
        not_if do
          # Don't try to install if package and version are already installed
          node['packages'].key?(pkg['display_name']) &&
          node['packages'][pkg['display_name']]['version'].eql?(pkg['version'])
        end
      end
    end
  end

  def manage
    debian_manage if node.debian_family?
    macos_manage if node.macos?
    windows_manage if node.windows?
  end

  def debian_manage
    # TODO: need to write
    return
  end

  def macos_manage
    # If the Anyconnect App goes missing, either by accident or abuse, trigger re-install
    ac_receipt = node['cpe_anyconnect']['pkg']['receipt']
    unless ::Dir.exist?(node['cpe_anyconnect']['app_path'])
      execute "/usr/sbin/pkgutil --forget #{ac_receipt}" do
        not_if { shell_out("/usr/sbin/pkgutil --pkg-info #{ac_receipt}").error? }
      end
    end
  end

  def windows_manage
    if anyconnect_service_status.nil?
      if node['packages'].include?('Cisco AnyConnect Secure Mobility Client')
        Chef::Log.warn('Anyconnect is installed but [vpnagent] service has been removed')
      end
    elsif anyconnect_service_status.include?('Running')
      Chef::Log.info('Anyconnect service [vpnagent] is running')
    elsif anyconnect_service_status.include?('Stopped')
      Chef::Log.info('Anyconnect service [vpnagent] is stopped')
    end

    cisco_install_path = ::File.join(ENV['ProgramFiles(x86)'], 'Cisco/Cisco AnyConnect Secure Mobility Client')
    app_link = ::File.join(cisco_install_path, 'vpnui.exe')
    if node['cpe_anyconnect']['desktop_shortcut']
      # Create Icon for Cisco AnyConnect Secure Mobility Client
      windows_shortcut desktop_link do
        iconlocation ::File.join(cisco_install_path, 'res/GUI.ico')
        description 'Cisco AnyConnect Secure Mobility Client'
        target app_link
        only_if { ::File.exist?(app_link) }
        not_if { ::File.exist?(desktop_link) }
      end
    else
      # Remove Icon for Cisco AnyConnect Secure Mobility Client
      remove_desktop_link
    end
  end

  def uninstall
    debian_uninstall if node.debian_family?
    macos_uninstall if node.macos?
    windows_uninstall if node.windows?
  end

  def debian_uninstall
    # TODO: need to write
    return
  end

  def macos_uninstall
    # TODO: need to write
    return
  end

  def windows_uninstall
    # Ensure the cache directory exists so we can download packages needed to uninstall
    create_anyconnect_cache

    # Move core and dart modules to the end of array so these are uninstalled last
    modules = node['cpe_anyconnect']['modules'].dup
    core = modules.index { |k| k['name'].eql?('core') }
    dart = modules.index { |k| k['name'].eql?('dart') }
    modules[core], modules[modules.count - 2] = modules[modules.count - 2], modules[core] unless core.nil?
    modules[dart], modules[modules.count - 1] = modules[modules.count - 1], modules[dart] unless dart.nil?

    modules.each do |pkg|
      # Download the anyconnect msi
      cpe_remote_file app_name do
        file_name pkg_filename(pkg)
        checksum pkg['checksum']
        path pkg_path(pkg)
        only_if { node['packages'].key?(pkg['display_name']) }
      end

      # We need to download each uninstaller because Chef does not properly uninstall using display_name
      # Only download the uninstaller if module is installed
      windows_package "Uninstall #{pkg['display_name']}" do
        source pkg_path(pkg)
        checksum pkg['checksum']
        action :remove
        options '/qn /norestart'
        only_if { node['packages'].key?(pkg['display_name']) }
      end
    end

    # Remove Desktop Link
    remove_desktop_link
  end

  def cache_path
    node['cpe_anyconnect']['pkg']['cache_path']
  end

  def app_name
    node['cpe_anyconnect']['pkg']['app_name']
  end

  def anyconnect_root_cache_path
    ::File.join(cache_path, app_name)
  end

  def create_anyconnect_cache
    # Create cache path
    directory anyconnect_root_cache_path do
      group root_group
      owner root_owner
      recursive true
      mode '0755'
    end
  end

  def sync_anyconnect_cache
    # Sync the entire anyconnect folder to handle any files an admin would need
    remote_directory anyconnect_root_cache_path do
      group root_group
      owner root_owner
      mode '0755'
      source 'anyconnect'
    end
  end

  def download_package(pkg)
    cpe_remote_file app_name do
      file_name pkg_filename(pkg)
      checksum pkg['checksum']
      path pkg_path(pkg)
    end
  end

  def pkg_path(pkg)
    ::File.join(anyconnect_root_cache_path, pkg_filename(pkg))
  end

  def pkg_filename(pkg)
    # Since Windows and MacOS naming is different, we need to return different filepaths
    # depending on if the package is a module or a macos package
    pkg['app_name'].nil? ? "#{app_name}-#{pkg['name']}-#{pkg['version']}.msi" : "#{app_name}-#{pkg['version']}.pkg"
  end

  def anyconnect_service_status
    return nil unless node.windows?
    status = powershell_out('(Get-Service vpnagent).status').stdout.to_s.chomp
    status.empty? ? nil : status
  end

  def desktop_link
    ::File.join(ENV['PUBLIC'], 'Desktop', 'Cisco Anyconnect Secure Mobility Client.lnk')
  end

  def remove_desktop_link
    file desktop_link do
      action :delete
    end
  end
end
