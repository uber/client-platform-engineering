#
# Cookbook:: cpe_crowdstrike_falcon_sensor
# Resources:: cpe_crowdstrike_falcon_sensor
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

resource_name :cpe_crowdstrike_falcon_sensor
provides :cpe_crowdstrike_falcon_sensor, :os => ['darwin', 'linux', 'windows']

default_action :manage

action :manage do
  install if install?
  manage if manage?
  uninstall if !install? && uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def falcon_agent_prefs
    node['cpe_crowdstrike_falcon_sensor']['agent']
  end

  def falcon_pkg_prefs
    node['cpe_crowdstrike_falcon_sensor']['pkg']
  end

  def install?
    node['cpe_crowdstrike_falcon_sensor']['install']
  end

  def manage?
    node['cpe_crowdstrike_falcon_sensor']['manage']
  end

  def minimum_supported_version
    node['cpe_crowdstrike_falcon_sensor']['minimum_supported_version']
  end

  def falcon_support_path
    node['cpe_crowdstrike_falcon_sensor']['agent']['falcon_support_path']
  end

  def uninstall?
    node['cpe_crowdstrike_falcon_sensor']['uninstall']
  end

  def install
    return unless node['cpe_crowdstrike_falcon_sensor']['install']

    # Loop through all the keys and bail/warn if any are missing that are required per OS
    run_install_logic = true
    [falcon_agent_prefs.to_hash, falcon_pkg_prefs.to_hash].each do |hash|
      # Grab the keys and check if they are empty strings or nils
      hash.each_key do |preference|
        if hash[preference].nil? || hash[preference].to_s.empty?
          # Warn and print out the bad key/value pairs
          Chef::Log.warn("cpe_crowdstrike_falcon_sensor incorrectly configured preference - #{preference}")
          # Force a safe return so chef doesn't hard crash
          run_install_logic = false
        end
      end
    end

    unless run_install_logic
      Chef::Log.warn('cpe_crowdstrike_falcon_sensor incorrectly configured. Skipping install')
      return
    end

    if Gem::Version.new(minimum_supported_version) > Gem::Version.new(falcon_pkg_prefs['version'])
      Chef::Log.warn("cpe_crowdstrike_falcon_sensor only installs crowdstrike v#{minimum_supported_version} and "\
        'higher. Please use a prior version of this cookbook if you need earlier support.')
      return
    end

    # Values for things we call in functions later
    cid = falcon_agent_prefs['customer_id']
    reg_token = falcon_agent_prefs['registration_token']
    receipt = falcon_pkg_prefs['mac_os_x_pkg_receipt']

    debian_install(cid, reg_token) if debian?
    macos_install(receipt, reg_token) if macos?
    windows_install(reg_token) if windows?
  end

  def debian_install(cid, reg_token, falconctl_path = falcon_agent_prefs['falconctl_path'])
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

  def macos_install(receipt, reg_token, falconctl_path = falcon_agent_prefs['falconctl_path'])
    if node.os_less_than?('10.14.5')
      Chef::Log.warn('cpe_crowdstrike_falcon_sensor only supports macOS Mojave 10.14.5 and higher. Please use a prior '\
        'version of this cookbook if you need earlier support.')
      return
    end

    # Force a re-install of CrowdStrike if files are missing
    execute "/usr/sbin/pkgutil --forget #{receipt}" do
      not_if { macos_cs_file_integrity_healthy? }
      not_if { shell_out("/usr/sbin/pkgutil --pkg-info #{receipt}").error? }
    end

    file_name = "#{node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name']}-"\
    "#{node['cpe_crowdstrike_falcon_sensor']['pkg']['version']}.pkg"
    file_path = ::File.join(Chef::Config[:file_cache_path], file_name)

    cpe_remote_file node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name'] do
      backup 1
      file_name file_name
      checksum node['cpe_crowdstrike_falcon_sensor']['pkg']['checksum']
      path file_path
    end

    # Cleanup old pkgs
    Dir[::File.join(Chef::Config[:file_cache_path], 'crowdstrike*.pkg')].each do |path|
      file path do
        action :delete
        not_if { path == file_path }
      end
    end

    # https://falcon.crowdstrike.com/support/documentation/22/falcon-sensor-for-mac-deployment-guide
    # Install the package
    cpe_remote_pkg 'Crowdstrike Falcon' do
      allow_downgrade node['cpe_crowdstrike_falcon_sensor']['pkg']['allow_downgrade']
      app node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name']
      version node['cpe_crowdstrike_falcon_sensor']['pkg']['version']
      checksum node['cpe_crowdstrike_falcon_sensor']['pkg']['checksum']
      receipt receipt
      backup 1
      only_if { node.macos_install_compat_check(file_path) }
    end
    # Enroll device into server with registration token, unless it's connecting or connected as the status.
    # See: TODO comment re: allowed_responses
    # allowed_responses = [
    #   'connecting',
    #   'connected',
    #   'delaying',
    # ]

    # Create the application support directories
    directory 'Ensure CrowdStrike directory path' do
      path falcon_support_path
      owner root_owner
      group node['root_group']
      mode '0755'
      recursive true
      only_if { node.macos_install_compat_check(file_path) }
    end

    # Only try to register the client if the license bin file doesn't exist.
    # The kernel extension wont load until it's registered.
    execute 'Setting Crowdstrike Falcon registration token' do
      command "#{falconctl_path} license #{reg_token}"
      only_if { ::File.exists?(falconctl_path) }
      # TODO - Uncomment this guard and the allowed_responses array aboveto re-arm machine if it hasn't
      #   checked-in in a few days.
      # not_if { allowed_responses.include?(check_falconctl_registration(falconctl_path)) }
      not_if { ::File.exists?(::File.join(falcon_support_path, 'License.bin')) }
      only_if { node.macos_install_compat_check(file_path) }
    end
  end

  def windows_install(reg_token)
    # https://falcon.crowdstrike.com/support/documentation/23/falcon-sensor-for-windows-deployment-guide
    version = node['cpe_crowdstrike_falcon_sensor']['pkg']['version']
    install_args = node['cpe_crowdstrike_falcon_sensor']['pkg']['args']
    file_name = "#{node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name']}-#{version}.exe"
    exe_path = ::File.join(Chef::Config[:file_cache_path], file_name)
    install_string = "#{exe_path} /install /quiet /norestart CID=#{reg_token}"
    install_string += ' VDI=1' if install_args['vdi']
    install_string += ' NO_START=1' if install_args['no_start']
    # ProvNoWait=1 means it doesn't wait until it can communicate to CS servers to install itself.
    install_string += ' ProvNoWait=1' if install_args['prov_no_wait']
    cpe_remote_file node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name'] do
      backup 1
      file_name file_name
      checksum node['cpe_crowdstrike_falcon_sensor']['pkg']['checksum']
      path exe_path
      mode '0644'
    end
    # Install the package and enroll with registration token
    execute 'Install Crowdstrike Falcon Windows' do
      command install_string
      only_if { ::File.exists?(exe_path) }
      # There technically isn't a falconctl on Windows, so you have to use sc and see if the process is running - if it
      # is, the device is in a good state
      not_if { check_falcon_agent_status_windows.include?('RUNNING') }
    end

    # Force an upgrade of CrowdStrike on Windows if it's out of date
    c_version = get_falcon_agent_version_windows
    if Gem::Version.new(version) > Gem::Version.new(c_version)
      execute 'Upgrade Crowdstrike Falcon Windows' do
        command install_string
        only_if { ::File.exists?(exe_path) }
      end
    end
  end

  def manage
    return unless node['cpe_crowdstrike_falcon_sensor']['manage']

    if Gem::Version.new(minimum_supported_version) > Gem::Version.new(
      node['cpe_crowdstrike_falcon_sensor']['pkg']['version'],
    )
      Chef::Log.warn("cpe_crowdstrike_falcon_sensor only manages crowdstrike v#{minimum_supported_version} and "\
        'higher. Please use a prior version of this cookbook if you need earlier support.')
      return
    end

    debian_manage if debian?
    macos_manage if macos?
    windows_manage if windows?
  end

  def debian_manage
    # Ensure falcon-sensor is running
    service 'falcon-sensor' do
      action %i[enable start]
    end
  end

  def macos_manage(falconctl_path = falcon_agent_prefs['falconctl_path'])
    # Big Sur and higher support System Extensions whereas Mojave/Catalina supports Kernel Extension
    # Modern installs currently support macOS 10.15 -> 13.0
    # 6.25.13807.0 is the last modern install version that supports 10.14 (Mojave)
    if node.os_less_than?('10.14')
      Chef::Log.warn('cpe_crowdstrike_falcon_sensor only manages macOS Mojave and higher. Please use a prior version '\
        'of this cookbook if you need earlier support.')
      return
    end

    # Purge the kext staging cache CrowdStrike kext if it's not healthy. Otherwise this could tank chef runs.
    kext_path = '/Applications/Falcon.app/Contents/Extensions/Agent.kext'
    if node.catalina? || node.mojave?
      execute 'Purge kext staging cache' do
        command '/usr/sbin/kextcache --clear-staging'
        only_if { ::File.exists?(kext_path) }
        only_if { kernel_extension_healthy?(kext_path) == false }
      end

      # Try to load the kernel extension, but only if it's healthy
      execute 'Force load the kernel extension' do
        command "/sbin/kextload #{kext_path}"
        only_if { ::File.exists?(kext_path) }
        only_if { kernel_extension_healthy?(kext_path) == true }
        only_if { ::File.exists?('/Library/Application Support/CrowdStrike/Falcon/License.bin') }
        not_if { kernel_extension_running? }
      end
    end

    # All installs require LaunchAgent
    [
      'com.crowdstrike.falcon.UserAgent',
    ].each do |agent|
      launchd agent do
        action :enable
        only_if { ::File.exist?("/Library/LaunchAgents/#{agent}.plist") }
        type 'agent'
      end
    end

    return unless ::File.exists?(falconctl_path)

    if node.at_least_big_sur?
      # System Extension installs requires LaunchDaemon as well
      [
        'com.crowdstrike.falcond',
      ].each do |daemon|
        # Turn on the launch daemons if they have been turned off
        launchd daemon do
          only_if { ::File.exist?("/Library/LaunchDaemons/#{daemon}.plist") }
          action :enable
        end
      end

      # Enable CrowdStrike
      execute 'Force enable Crowdstrike' do
        command "#{falconctl_path} load --force"
        only_if { falconctl_healthy? == false }
      end

      # Enable or Disable the network filter if being managed - OS >= Big Sur
      if falconctl_healthy? &&
        falcon_agent_prefs['manage_network_filter'] &&
        node.at_least?(node.chef_version, '17.7.22')
        ext_enabled, ext_error = node.network_extension_enabled('com.crowdstrike.falcon.App', 'contentFilter')
        if falcon_agent_prefs['enable_network_filter']
          execute 'Enable Crowdstrike network filter' do
            command "#{falconctl_path} enable-filter"
            not_if { ext_error }
            only_if { ext_enabled == false }
          end
        else
          execute 'Disable Crowdstrike network filter' do
            command "#{falconctl_path} disable-filter"
            not_if { ext_error }
            only_if { ext_enabled }
          end
        end
      end
    end

    # Grouping Tags
    if Gem::Version.new(falcon_pkg_prefs['version']) >= Gem::Version.new('6.0.0.0')
      grouping_tags = node['cpe_crowdstrike_falcon_sensor']['grouping_tags']
      node.safe_nil_empty?(grouping_tags) ? clear_grouping_tags : append_grouping_tags(grouping_tags)
    end
  end

  # returns an array of existing grouping tags.
  def get_grouping_tags(falconctl_path = falcon_agent_prefs['falconctl_path'])
    if macos?
      command = "#{falconctl_path} grouping-tags get"
      command_out = shell_out(command)
      command_tokenize = command_out.stdout.strip.split(': ')
      return [] if node.safe_nil_empty?(command_tokenize)
      return [] if command_tokenize[0].include?('No grouping tags set')

      return command_tokenize.last.split(',') unless command_tokenize.empty? && command_tokenize.length > 1

      return []
    elsif windows?
      # Get subkey values
      subkeys = registry_get_values(windows_grouping_tags_regkey)
      return [] if node.safe_nil_empty?(subkeys)

      subkeys.each do |key|
        return key[:data].split(',') if key[:name] == 'GroupingTags'
      end
      return []
    end
  end

  # append a new grouping tag to existing tags
  def append_grouping_tags(new_tags)
    if macos? || windows?
      existing_tags = get_grouping_tags
      delta_array = existing_tags.union(new_tags)
      set_grouping_tags(delta_array) if delta_array.sort != existing_tags.sort
    end
  end

  # clear the sensor grouping tags
  def clear_grouping_tags(falconctl_path = falcon_agent_prefs['falconctl_path'])
    if macos?
      execute 'clear sensor grouping tags' do
        command "#{falconctl_path} grouping-tags clear"
        only_if { ::File.exists?(falconctl_path) }
      end

    elsif windows?
      registry_key windows_grouping_tags_regkey do
        values [{
          :name => 'GroupingTags',
          :type => :string,
          :data => nil,
        }]
      end
    end
  end

  # sets the sensor grouping tags.
  def set_grouping_tags(new_tags, falconctl_path = falcon_agent_prefs['falconctl_path'])
    return unless new_tags.is_a?(Array)

    if macos?
      execute 'set sensor grouping tags' do
        command "#{falconctl_path} grouping-tags set #{new_tags.join(',')}"
        not_if { new_tags.empty? }
        only_if { ::File.exists?(falconctl_path) }
      end

    elsif windows?
      registry_key windows_grouping_tags_regkey do
        values [{
          :name => 'GroupingTags',
          :type => :string,
          :data => new_tags.join(','),
        }]
      end
    end
  end

  def windows_grouping_tags_regkey
    'HKEY_LOCAL_MACHINE\SYSTEM\CrowdStrike\{9b03c1d9-3138-44ed-9fae-d9f4c034b88d}'\
    '\{16e0423f-7058-48c9-a204-725362b67639}\Default'
  end

  def windows_manage
    # Grouping Tags
    if Gem::Version.new(falcon_pkg_prefs['version']) >= Gem::Version.new('6.0.0.0')
      grouping_tags = node['cpe_crowdstrike_falcon_sensor']['grouping_tags']
      node.safe_nil_empty?(grouping_tags) ? clear_grouping_tags : append_grouping_tags(grouping_tags)
    end
  end

  def uninstall
    return unless node['cpe_crowdstrike_falcon_sensor']['uninstall']

    # Loop through all the keys and bail/warn if any are missing that are required per OS
    run_uninstall_logic = true
    check_hash = {}
    if macos?
      check_hash[:falconctl_path] = falcon_agent_prefs['falconctl_path']
    elsif windows?
      check_hash[:app_name] = falcon_pkg_prefs['app_name']
      check_hash[:uninstall_checksum] = falcon_pkg_prefs['uninstall_checksum']
      check_hash[:uninstall_version] = falcon_pkg_prefs['uninstall_version']
    end
    # Grab the keys and check if they are empty strings or nils
    check_hash.each_key do |preference|
      if check_hash[preference].to_s.empty? || check_hash[preference].nil?
        # Warn and print out the bad key/value pairs
        Chef::Log.warn('cpe_crowdstrike_falcon_sensor incorrectly configured. Skipping uninstall')
        Chef::Log.warn("cpe_crowdstrike_falcon_sensor preference - #{preference}")
        # Force a safe return so chef doesn't hard crash
        run_uninstall_logic = false
      end
    end

    return unless run_uninstall_logic

    debian_uninstall if debian?
    macos_uninstall if macos?
    windows_uninstall if windows?
  end

  def debian_uninstall
    # https://falcon.crowdstrike.com/support/documentation/20/falcon-sensor-for-linux-deployment-guide
    dpkg_package 'falcon-sensor' do
      action :purge
    end
  end

  def macos_uninstall(falconctl_path = falcon_agent_prefs['falconctl_path'])
    # Uninstall software with falconctl
    execute 'Uninstall Crowdstrike Falcon macOS' do
      command "#{falconctl_path} uninstall"
      only_if { ::File.exists?(falconctl_path) }
    end

    directory '/Library/Application Support/CrowdStrike' do
      action :delete
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
      only_if { check_falcon_agent_status_windows.include?('RUNNING') }
    end
  end

  def macos_cs_file_integrity_healthy?
    healthy = true
    files_to_check = %w[
      /Applications/Falcon.app/Contents/Resources/falconctl
      /Library/LaunchAgents/com.crowdstrike.falcon.UserAgent.plist
    ]
    if node.catalina? || node.mojave?
      files_to_check += %w[
        /Library/LaunchDaemons/com.crowdstrike.falcond.plist
        /Applications/Falcon.app/Contents/Extensions/Agent.kext
        /Applications/Falcon.app/Contents/Resources/falcond
      ]
    else
      files_to_check += %w[
        /Applications/Falcon.app/Contents/Library/SystemExtensions/com.crowdstrike.falcon.Agent.systemextension
      ]
    end
    files_to_check.each do |cs_file|
      unless ::File.exists?(cs_file)
        return false
      end
    end

    if node.at_least_big_sur? && !node.system_extension_installed?('com.crowdstrike.falcon.Agent.systemextension')
      return false
    end

    healthy
  end

  def kernel_extension_running?
    status = false
    if macos?
      cmd = shell_out('/usr/sbin/kextstat -b com.crowdstrike.sensor').stdout.to_s
      if cmd.nil? || cmd.empty?
        return status
      else
        status = cmd.include?('com.crowdstrike.sensor')
      end
    end
    status
  end

  def kernel_extension_healthy?(kext_path)
    status = false
    if macos?
      cmd = shell_out("/usr/bin/kextutil #{kext_path} -n -t")
      if cmd.nil?
        return status
      else
        status = cmd.exitstatus.zero?
      end
    end
    status
  end

  def check_falconctl_registration(falconctl_path = falcon_agent_prefs['falconctl_path'])
    # Blank strings for our comparisons vs nil because of our guards.
    status = ''

    return status if (debian? || macos?) && !::File.exists?(falconctl_path)

    if macos?
      cmd = shell_out("#{falconctl_path} stats").stdout.to_s
      if cmd.nil? || cmd.empty?
        return status
      else
        # Capture all values after State: but before the trailing space
        status = cmd[/State: (.*?)(?=\s)/, 1]
      end
    elsif debian?
      cmd = shell_out("#{falconctl_path} -g --cid").stdout.to_s
      if cmd.nil? || cmd.empty?
        return status
      else
        status = cmd[/cid..(\w+)/, 1] # capture all alpha_numeric after cid
      end
    end
    status
  end

  def falconctl_healthy?(falconctl_path = falcon_agent_prefs['falconctl_path'])
    status = false
    if macos?
      if node.catalina? || node.mojave?
        cmd = shell_out("#{falconctl_path} stats")
        status = cmd.nil? ? false : cmd.exitstatus.zero?
      else
        cmd = shell_out("#{falconctl_path} stats agent_info --plist").stdout
        if cmd.nil? || cmd.empty?
          return false
        else
          cmd_plist = Plist.parse_xml(cmd)
        end
        if cmd_plist.nil? || cmd_plist.empty?
          return false
        else
          sensor_operational = cmd_plist['agent_info']['sensor_operational']
        end

        status = sensor_operational.nil? ? false : sensor_operational.downcase == 'true'
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
