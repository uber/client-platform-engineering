#
# Cookbook:: cpe_anyconnect
# Resources:: cpe_anyconnect
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2021-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

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
    debian_install if debian?
    macos_install if macos?
    windows_install if windows?
  end

  def debian_install
    # TODO: need to write
    return
  end

  def macos_install
    # Create the cache directories and stage necessary files
    create_anyconnect_cache
    sync_anyconnect_cache

    # cpe_remote_pkg doesn't support ChoiceChanges.xml which is needed to not install specific parts of this package
    # Download the anyconnect pkg
    download_package(pkg)

    # Install the pacakge with the ChoiceChangesXML
    cc_xml_path = ::File.join(anyconnect_root_cache_path, 'pkg', 'ChoiceChanges.xml')
    allow_downgrade = pkg['allow_downgrade']
    if allow_downgrade
      if node.os_at_least?('12.0') && node.sext_profile_removal_contains_extension?(
        'com.cisco.anyconnect.macos.acsockext', 'DE8Y96K9QP', node['cpe_anyconnect']['profile_identifier']
      )
        execute '/opt/cisco/anyconnect/bin/anyconnect_uninstall.sh' do
          not_if { node.macos_package_installed?(pkg['receipt'], pkg['version']) }
          not_if { anyconnect_vpn_connected? }
          only_if { ::File.exist?('/opt/cisco/anyconnect/bin/anyconnect_uninstall.sh') }
        end
        execute '/opt/cisco/anyconnect/bin/dart_uninstall.sh' do
          not_if { node.macos_package_installed?(pkg['dart_receipt'], pkg['version']) }
          not_if { anyconnect_vpn_connected? }
          only_if { ::File.exist?('/opt/cisco/anyconnect/bin/dart_uninstall.sh') }
        end
      else
        Chef::Log.warn('cpe_anyconnect - AnyConnect package has logic to fail if attempting to downgrade - you must '\
          'manually uninstall the application first if you are not passing a system extension profile!')
        Chef::Log.warn('cpe_anyconnect - forcing downgrade to false')
        allow_downgrade = false
      end
    end

    execute "/usr/sbin/installer -applyChoiceChangesXML #{cc_xml_path} -pkg #{pkg_path(pkg)} -target /" do
      # functionally equivalent to allow_downgrade false on cpe_remote_pkg
      if allow_downgrade
        not_if { node.macos_package_installed?(pkg['receipt'], pkg['version']) }
      else
        not_if { node.macos_min_package_installed?(pkg['receipt'], pkg['version']) }
      end
      not_if { anyconnect_vpn_connected? }
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

    if node['cpe_anyconnect']['umbrella_diagnostic_link']
      umbrella_diagnostic_link
    end
  end

  def windows_install
    # Create the cache directories and stage necessary files
    create_anyconnect_cache
    sync_anyconnect_cache
    # Add precheck / remediation before running through install.
    windows_error_prevention

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
        not_if { anyconnect_vpn_connected? }
        not_if do
          # Don't try to install if package and version are already installed
          (node['packages'].key?(pkg['display_name']) &&
          node['packages'][pkg['display_name']]['version'].eql?(pkg['version']))
        end
      end
    end
  end

  def manage
    debian_manage if debian?
    macos_manage if macos?
    windows_manage if windows?
  end

  def debian_manage
    # TODO: need to write
    return
  end

  def macos_manage
    # If the Anyconnect App goes missing, either by accident or abuse, trigger re-install
    ac_receipt = pkg['receipt']
    orgid = node['cpe_anyconnect']['organization_id']
    unless ::Dir.exist?(node['cpe_anyconnect']['app_path'])
      execute "/usr/sbin/pkgutil --forget #{ac_receipt}" do
        not_if { shell_out("/usr/sbin/pkgutil --pkg-info #{ac_receipt}").error? }
      end
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

    # Ensure the anyconnect VPN Agent daemon is enabled
    launchd 'com.cisco.anyconnect.vpnagentd-manage' do
      action :enable
      label 'com.cisco.anyconnect.vpnagentd'
      only_if { ::File.exist?('/Library/LaunchDaemons/com.cisco.anyconnect.vpnagentd.plist') }
      type 'daemon'
      notifies :create, 'file[trigger_gui]', :immediately
    end

    # Disable VPN and trigger a re-enroll by deleting the data folder if the nslookup fails
    # Backup logs before directory deletion option.
    unless orgid.nil?
      ruby_block 'backup beacon logs' do
        block do
          Chef::Log.info(
            'Backup beacon /opt/cisco/anyconnect/umbrella/data/beacon-logs/ ' \
            '- trigger re-enroll of anyconnect client',
          )
          require 'fileutils'
          FileUtils.cp_r(
            '/opt/cisco/anyconnect/umbrella/data/beacon-logs',
            '/var/log',
          )
        end
        action :nothing
        only_if { node['cpe_anyconnect']['backup_logs'] }
      end

      directory '/opt/cisco/anyconnect/umbrella/data' do
        action :nothing
        notifies :disable, 'launchd[com.cisco.anyconnect.vpnagentd-manage]', :before
        notifies :enable, 'launchd[com.cisco.anyconnect.vpnagentd-manage]', :immediately
        recursive true
      end

      ruby_block 'Delete /opt/cisco/anyconnect/umbrella/data - trigger re-enroll of anyconnect client' do
        block do
          Chef::Log.info('Delete /opt/cisco/anyconnect/umbrella/data - trigger re-enroll of anyconnect client')
        end
        notifies :run, 'ruby_block[backup beacon logs]', :immediately
        notifies :delete, 'directory[/opt/cisco/anyconnect/umbrella/data]', :immediately
        not_if { nslookup(orgid) }
        only_if { node.macos_min_package_installed?(ac_receipt, '4.9.06037') }
        only_if { node.daemon_running?('com.cisco.anyconnect.vpnagentd') } # must be loaded to return nslookup data
        only_if { Time.now.to_i - Time.at(node.macos_boottime).to_i >= 300 } # takes a bit to fully load on boot
        only_if { Time.now.to_i - Time.at(node.macos_waketime).to_i >= 300 } # takes a bit to fully load upon wake
        # anyconnect must be on for a few to fully activate nslookup, otherwise this could loop infinitely
        only_if { node.macos_process_uptime('vpnagentd') >= 300 }
      end
    end
  end

  def windows_manage
    if windows_vpnagent_service_status.nil?
      if node['packages'].include?('Cisco AnyConnect Secure Mobility Client')
        Chef::Log.warn('Anyconnect is installed but [vpnagent] service has been removed')
      end
    elsif windows_vpnagent_service_status.include?('Running')
      Chef::Log.info('Anyconnect service [vpnagent] is running')
    elsif windows_vpnagent_service_status.include?('Stopped')
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
    debian_uninstall if debian?
    macos_uninstall if macos?
    windows_uninstall if windows?
  end

  def debian_uninstall
    # TODO: need to write
    return
  end

  def macos_uninstall
    execute '/opt/cisco/anyconnect/bin/anyconnect_uninstall.sh' do
      only_if { ::File.exist?('/opt/cisco/anyconnect/bin/anyconnect_uninstall.sh') }
    end

    execute '/opt/cisco/anyconnect/bin/dart_uninstall.sh' do
      only_if { ::File.exist?('/opt/cisco/anyconnect/bin/dart_uninstall.sh') }
    end
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

    # Remove AppData Files
    directory ::File.join(ENV['PROGRAMDATA'], 'Cisco/Cisco AnyConnect Secure Mobility Client') do
      action :delete
      recursive true
      ignore_failure true
    end

    # Remove Desktop Link
    remove_desktop_link
  end

  def pkg
    node['cpe_anyconnect']['pkg'].to_hash
  end

  def cache_path
    pkg['cache_path']
  end

  def app_name
    pkg['app_name']
  end

  def anyconnect_root_cache_path
    ::File.join(cache_path, app_name)
  end

  def create_anyconnect_cache
    # Create cache path
    directory anyconnect_root_cache_path do
      group node['root_group']
      owner root_owner
      recursive true
      mode '0755'
    end
  end

  def sync_anyconnect_cache
    # Sync the entire anyconnect folder to handle any files an admin would need
    remote_directory anyconnect_root_cache_path do
      group node['root_group']
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

  def bfe_service_group
    # Required to find which svchost group the bfe service is assigned to.
    # Either LocalServiceNoNetwork or LoclalServiceNoNetworkFirewall
    return nil unless windows?

    cmd = "(Get-WMIObject Win32_Service -Filter \"Name='BFE'\")"
    group = powershell_out("(#{cmd}.PathName).split(' ')[2]").stdout.to_s.chomp
    group.empty? ? nil : group
  end

  def bfe_registry
    return nil unless windows?

    # Grabs registry value of svchost group and adds BFE to the list
    base = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost'
    cmd = "(Get-ItemProperty -Path 'registry::#{base}')"
    values = powershell_out("#{cmd}.#{bfe_service_group}").stdout.to_s.chomp.split(' ')
    values.push('BFE') unless values.include?('BFE')
    return values unless values.nil? || values.empty?

    'BFE'
  end

  def anyconnect_vpn_connected?
    return false unless windows? || macos?

    client =
      if windows?
        ::File.join(ENV['ProgramFiles(x86)'], 'Cisco/Cisco AnyConnect Secure Mobility Client/vpncli.exe')
      elsif macos?
        '/opt/cisco/anyconnect/bin/vpn'
      end

    return false unless ::File.exist?(client)

    if windows?
      exe = 'Cisco/Cisco AnyConnect Secure Mobility Client/vpncli.exe'
      result = powershell_out("(& (Join-path -Path ${ENV:ProgramFiles(x86)} -ChildPath '#{exe}') state)").stdout.to_s
    elsif macos?
      result = `#{client} state`
    end
    result&.include?('state: Connected')
  end

  def desktop_link
    # set default location if ENV['PUBLIC'] is not assigned
    public = ENV['PUBLIC'] || 'C:/Users/Public'
    ::File.join(public, 'Desktop', 'Cisco Anyconnect Secure Mobility Client.lnk')
  end

  def remove_desktop_link
    file desktop_link do
      action :delete
    end
  end

  def umbrella_diagnostic_link
    umbrella_diagnostic_path = '/opt/cisco/anyconnect/bin/UmbrellaDiagnostic.app'
    link node['cpe_anyconnect']['umbrella_diagnostic_link'] do
      to umbrella_diagnostic_path
      only_if { ::File.exist?(umbrella_diagnostic_path) }
    end
  end

  def windows_error_prevention
    # Resolves 1603 error when installing on Windows devices (known issue)
    return if bfe_service_group.nil?

    registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost' do
      values [{
        'name' => bfe_service_group, 'type' => :multi_string, 'data' => bfe_registry
      }]
      action :create
    end

    windows_service 'BFE' do
      action :start
    end
  end

  def windows_vpnagent_service_status
    return nil unless windows?

    status = powershell_out('(Get-Service vpnagent).status').stdout.to_s.chomp
    status.empty? ? nil : status
  end

  def nslookup(orgid)
    count = 0
    json_path = ::File.join(anyconnect_root_cache_path, 'cpe_anyconnect.json')
    guard_successful = true
    unless node.nslookup_txt_records('debug.opendns.com')['orgid'] == orgid
      if ::File.exists?(json_path)
        count = node.parse_json(json_path)['nslookup_failures'] + 1
      else
        count = 1
      end
    end

    if count > node['cpe_anyconnect']['nslookup_failure_count_threshold']
      count = 0
      guard_successful = false
    end

    write_json(count, json_path)
    return guard_successful
  end

  def write_json(count, json_path)
    if count == 0
      file json_path do
        action :delete
      end
    else
      file json_path do
        action :create
        content Chef::JSONCompat.to_json_pretty({ 'nslookup_failures' => count })
      end
    end
  end
end
