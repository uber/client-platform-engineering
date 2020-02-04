#
# Cookbook Name:: cpe_crowdstrike_falcon_sensor
# Resources:: cpe_crowdstrike_falcon_sensor
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_crowdstrike_falcon_sensor
provides :cpe_crowdstrike_falcon_sensor
default_action :manage

action :manage do
  install if install?
  manage if manage?
  uninstall if !install? && uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    node['cpe_crowdstrike_falcon_sensor']['install']
  end

  def manage?
    node['cpe_crowdstrike_falcon_sensor']['manage']
  end

  def uninstall?
    node['cpe_crowdstrike_falcon_sensor']['uninstall']
  end

  def install
    return unless node['cpe_crowdstrike_falcon_sensor']['install']

    # Root preferences for agent and package
    falcon_agent_prefs = node['cpe_crowdstrike_falcon_sensor']['agent'].to_hash
    falcon_pkg_prefs = node['cpe_crowdstrike_falcon_sensor']['pkg'].to_hash

    # Loop through all the keys and bail/warn if any are missing that are required per OS
    run_install_logic = true
    [falcon_agent_prefs, falcon_pkg_prefs].each do |hash|
      # Grab the keys and check if they are empty strings or nils
      hash.keys.each do |preference|
        if hash[preference].to_s.empty? || hash[preference].nil?
          # Warn and print out the bad key/value pairs
          Chef::Log.warn('cpe_crowdstrike_falcon_sensor incorrectly configured. Skipping install')
          Chef::Log.warn("cpe_crowdstrike_falcon_sensor preference - #{preference}")
          # Force a safe return so chef doesn't hard crash
          run_install_logic = false
        end
      end
    end

    return unless run_install_logic

    # Values for things we call in functions later
    cid = falcon_agent_prefs['customer_id']
    falconctl_path = falcon_agent_prefs['falconctl_path']
    reg_token = falcon_agent_prefs['registration_token']
    receipt = falcon_pkg_prefs['mac_os_x_pkg_receipt']

    debian_install(falconctl_path, cid, reg_token) if node.debian_family?
    macos_install(falconctl_path, receipt, reg_token) if node.macos?
    windows_install(reg_token) if node.windows?
  end

  def debian_install(falconctl_path, cid, reg_token)
    # https://falcon.crowdstrike.com/support/documentation/20/falcon-sensor-for-linux-deployment-guide
    file_name = "#{node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name']}-"\
      "#{node['cpe_crowdstrike_falcon_sensor']['pkg']['version']}.deb"
    deb_path = ::File.join(Chef::Config[:file_cache_path], file_name)
    cpe_remote_file node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name'] do
      backup 1
      file_name file_name
      checksum node['cpe_crowdstrike_falcon_sensor']['pkg']['checksum']
      path deb_path
      mode '0644'
    end
    # Install the package and enroll with registration token
    dpkg_package file_name do
      source deb_path
      version node['cpe_crowdstrike_falcon_sensor']['pkg']['dpkg_version']
      action :install
    end
    # Enroll device into server with registration token
    execute 'Setting Crowdstrike Falcon registration token' do
      command "#{falconctl_path} -s --cid=#{reg_token}"
      only_if { ::File.exists?(falconctl_path) }
      only_if { check_falconctl_registration(falconctl_path) != cid }
    end
    # Ensure falcon-sensor is running
    service 'falcon-sensor' do
      action %i[enable start]
    end
  end

  def macos_install(falconctl_path, receipt, reg_token)
    # https://falcon.crowdstrike.com/support/documentation/22/falcon-sensor-for-mac-deployment-guide
    # Install the package
    cpe_remote_pkg 'Crowdstrike Falcon' do
      allow_downgrade node['cpe_crowdstrike_falcon_sensor']['pkg']['allow_downgrade']
      app node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name']
      version node['cpe_crowdstrike_falcon_sensor']['pkg']['version']
      checksum node['cpe_crowdstrike_falcon_sensor']['pkg']['checksum']
      receipt receipt
    end
    # Enroll device into server with registration token, unless it's connecting or connected as the status.
    allowed_responses = [
      'connecting',
      'connected',
      'delaying',
    ]

    # Try to load the kernel extension
    execute 'Force load the kernel extension' do
      command '/sbin/kextload /Library/CS/kexts/Agent.kext'
      only_if { ::File.exists?('/Library/CS/kexts/Agent.kext') }
      not_if { kernel_extension_running }
    end

    # Only try to register the client if the kernel extension is running
    execute 'Setting Crowdstrike Falcon registration token' do
      command "#{falconctl_path} license #{reg_token}"
      only_if { ::File.exists?(falconctl_path) }
      # TODO - Change this guard to re-arm machine if it hasn't checked in in a few days.
      # not_if { allowed_responses.include?(check_falconctl_registration(falconctl_path)) }
      not_if { ::File.exists?('/Library/CS/License.bin') }
    end
  end

  def windows_install(reg_token)
    # https://falcon.crowdstrike.com/support/documentation/23/falcon-sensor-for-windows-deployment-guide
    version = node['cpe_crowdstrike_falcon_sensor']['pkg']['version']
    file_name = "#{node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name']}-#{version}.exe"
    exe_path = ::File.join(Chef::Config[:file_cache_path], file_name)
    cpe_remote_file node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name'] do
      backup 1
      file_name file_name
      checksum node['cpe_crowdstrike_falcon_sensor']['pkg']['checksum']
      path exe_path
      mode '0644'
    end
    # Install the package and enroll with registration token
    execute 'Install Crowdstrike Falcon Windows' do
      # ProvNoWait=1 means it doesn't wait until it can communicate to CS servers to install itself.
      command "#{exe_path} /install /quiet /norestart ProvNoWait=1 CID=#{reg_token}"
      only_if { ::File.exists?(exe_path) }
      # There technically isn't a falconctl on Windows, so you have to use sc and see if the process is running - if it
      # is, the device is in a good state
      not_if do
        check_falcon_agent_status_windows.include?('RUNNING')
      end
    end

    # Force an upgrade of CrowdStrike on Windows if it's out of date
    c_version = get_falcon_agent_version_windows
    if Gem::Version.new(version) > Gem::Version.new(c_version)
      execute 'Upgrade Crowdstrike Falcon Windows' do
        command "#{exe_path} /install /quiet /norestart CID=#{reg_token}"
        only_if { ::File.exists?(exe_path) }
      end
    end
  end

  def manage
    return unless node['cpe_crowdstrike_falcon_sensor']['manage']
    debian_manage if node.debian_family?
    macos_manage if node.macos?
    windows_manage if node.windows?
  end

  def debian_manage
    # Ensure falcon-sensor is running
    service 'falcon-sensor' do
      action %i[enable start]
    end
  end

  def macos_manage
    # TODO: need to write
    return
  end

  def windows_manage
    # TODO: need to write
    return
  end

  def uninstall
    return unless node['cpe_crowdstrike_falcon_sensor']['uninstall']

    # Root preferences for agent and package
    falcon_agent_prefs = node['cpe_crowdstrike_falcon_sensor']['agent']
    falcon_pkg_prefs = node['cpe_crowdstrike_falcon_sensor']['pkg']

    # Loop through all the keys and bail/warn if any are missing that are required per OS
    run_uninstall_logic = true
    check_hash = {}
    if node.macos?
      check_hash[:falconctl_path] = falcon_agent_prefs['falconctl_path']
    elsif node.windows?
      check_hash[:app_name] = falcon_pkg_prefs['app_name']
      check_hash[:uninstall_checksum] = falcon_pkg_prefs['uninstall_checksum']
      check_hash[:uninstall_version] = falcon_pkg_prefs['uninstall_version']
    end
    # Grab the keys and check if they are empty strings or nils
    check_hash.keys.each do |preference|
      if check_hash[preference].to_s.empty? || check_hash[preference].nil?
        # Warn and print out the bad key/value pairs
        Chef::Log.warn('cpe_crowdstrike_falcon_sensor incorrectly configured. Skipping uninstall')
        Chef::Log.warn("cpe_crowdstrike_falcon_sensor preference - #{preference}")
        # Force a safe return so chef doesn't hard crash
        run_uninstall_logic = false
      end
    end

    return unless run_uninstall_logic

    debian_uninstall if node.debian_family?
    macos_uninstall(falcon_agent_prefs['falconctl_path']) if node.macos?
    windows_uninstall if node.windows?
  end

  def debian_uninstall
    # https://falcon.crowdstrike.com/support/documentation/20/falcon-sensor-for-linux-deployment-guide
    dpkg_package 'falcon-sensor' do
      action :purge
    end
  end

  def macos_uninstall(falconctl_path)
    # Uninstall software with falconctl
    execute 'Uninstall Crowdstrike Falcon macOS' do
      command "#{falconctl_path} uninstall"
      only_if { ::File.exists?(falconctl_path) }
    end
  end

  def windows_uninstall
    # https://falcon.crowdstrike.com/support/documentation/23/falcon-sensor-for-windows-deployment-guide
    file_name = "#{node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name']}_uninstaller-"\
      "#{node['cpe_crowdstrike_falcon_sensor']['pkg']['uninstall_version']}.exe"
    exe_path = ::File.join(Chef::Config[:file_cache_path], file_name)
    un_hash = node['cpe_crowdstrike_falcon_sensor']['pkg']['uninstall_checksum']
    cpe_remote_file node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name'] do
      backup 1
      file_name file_name
      checksum un_hash
      path exe_path
      mode '0644'
    end
    execute 'Uninstall Crowdstrike Falcon Windows' do
      command "#{exe_path} /quiet"
      only_if { ::File.exists?(exe_path) }
      only_if do
        check_falcon_agent_status_windows.include?('RUNNING')
      end
    end
  end

  def kernel_extension_running
    status = false
    if node.macos?
      cmd = shell_out('/usr/sbin/kextstat -b com.crowdstrike.sensor').stdout.to_s
      if cmd.nil? || cmd.empty?
        return status
      else
        status = cmd.include?('com.crowdstrike.sensor')
      end
    end
    status
  end

  def check_falconctl_registration(falconctl_path)
    # Blank strings for our comparisons vs nil because of our guards.
    status = ''
    if node.debian_family? || node.macos?
      unless ::File.exists?(falconctl_path)
        return status
      end
    end
    if node.macos?
      cmd = shell_out("#{falconctl_path} stats").stdout.to_s
      if cmd.nil? || cmd.empty?
        return status
      else
        # Capture all values after State: but before the trailing space
        status = cmd[/State: (.*?)(?=\s)/, 1]
      end
    elsif node.debian_family?
      cmd = shell_out("#{falconctl_path} -g --cid").stdout.to_s
      if cmd.nil? || cmd.empty?
        return status
      else
        status = cmd[/cid..(\w+)/, 1] # capture all alpha_numeric after cid
      end
    end
    status
  end

  def check_falcon_agent_status_windows
    # Blank strings for our comparisons vs nil because of our guards.
    status = ''
    cmd = shell_out('C:\Windows\System32\sc.exe query csagent').stdout.to_s
    check_status = cmd[/STATE (.*)/, 1]
    if check_status.nil? || check_status.empty?
      return status
    else
      status = check_status.delete(' ').chomp
    end
    status
  end

  def get_falcon_agent_version_windows
    # Blank strings for our comparisons vs nil because of our guards.
    status = '0'
    powershell_cmd = '(Get-Item ${Env:ProgramFiles}\CrowdStrike\CSFalconContainer.exe).VersionInfo.FileVersion'
    cmd = powershell_out(powershell_cmd).stdout.to_s
    if cmd.nil? || cmd.empty?
      return status
    else
      status = cmd.chomp
    end
    status
  end
end
