#
# Cookbook:: cpe_workspaceone
# Resources:: cpe_workspaceone
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

resource_name :cpe_workspaceone
provides :cpe_workspaceone, :os => 'darwin'

default_action :manage

action :manage do
  # manage needs to go first if you are attempting to hide the agent from appearing showing it's UX to users.
  manage if manage?
  install if install?
  manage_cli_config if manage_cli_config?
  enforce_mdm_profiles if enforce_mdm_profiles?
  uninstall if !install? && uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  WS1_DEFAULT_PREFS = {
    'checkin-interval' => 60,
    'menubar-icon' => true,
    'sample-interval' => 60,
    'transmit-interval' => 60,
  }.freeze

  def enforce_mdm_profiles?
    node['cpe_workspaceone']['mdm_profiles']['enforce']
  end

  def install?
    node['cpe_workspaceone']['install']
  end

  def manage?
    node['cpe_workspaceone']['manage']
  end

  def manage_cli_config?
    node['cpe_workspaceone']['manage_cli']
  end

  def uninstall?
    node['cpe_workspaceone']['uninstall']
  end

  def enforce_mdm_profiles
    return unless node['cpe_workspaceone']['mdm_profiles']['enforce']

    macos_enforce_mdm_profiles if macos?
  end

  def set_cli_config(flag, val)
    default = WS1_DEFAULT_PREFS[flag]
    val ||= default
    cmd = node.hubcli_execute("config --set #{flag} #{val}")
    unless cmd.exitstatus.zero?
      if !cmd.stderr.include?('Error: Invalid value for option') || val == default
        cmd.error!
      end
      Chef::Log.warn("cpe_workspaceone - #{cmd.stderr.strip} (#{val}) - setting default")
      set_cli_config(flag, default)
    end
  end

  def manage_cli_config
    unless node.ws1_hubcli_exists
      Chef::Log.warn('cpe_workspaceone - hubcli path does not exist, cannot enforce MDM profiles!')
      return
    end

    prefs = node['cpe_workspaceone']['cli_prefs'].compact
    prefs.each do |flag, val|
      unless WS1_DEFAULT_PREFS.key?(flag)
        Chef::Log.warn("cpe_workspaceone - refusing to manage unknown cli preference '#{flag}'")
        next
      end

      set_cli_config(flag, val)
    end
  end

  def macos_enforce_mdm_profiles
    # Bail if path doesn't exist
    unless node.ws1_hubcli_exists
      Chef::Log.warn('cpe_workspaceone - hubcli path does not exist, cannot enforce MDM profiles!')
      return
    end

    device_forcelist = node['cpe_workspaceone']['mdm_profiles']['profiles']['device_forced'] || []

    # Bail if there are no device attributes
    device_attributes = node.ws1_device_attributes
    return if device_attributes.empty? || device_attributes.nil?

    # Loop through the enforced device profiles and compare with available profiles from MDM
    enforced_device_ws1_profiles = node['cpe_workspaceone']['mdm_profiles']['profiles']['device']
    device_attributes['DeviceProfiles'].each do |ws1_profile|
      profile_name = ws1_profile['Name']
      profile_id = ws1_profile['Id'].to_s
      profile_version = ws1_profile['CurrentVersion'].to_s
      # WS1 dynamically creates the DisplayName by taking the Name of the profile and how many revisions have been
      # done in the console. To make this simpler on the chef admin, we will concatenate the strings.
      installed_profile_name = profile_name + '/V_' + profile_version
      # Because of user/device level profiles being in one array, we need the if statement outside of the execute block
      if enforced_device_ws1_profiles.include?(profile_name)
        execute "Sending #{profile_name} for device installation to Workspace One console" do
          command node.hubcli_cmd("profiles --install #{profile_id}")
          only_if { node.ws1_hubcli_exists } # non-gsub or guard will fail.
          not_if do
            node.profile_installed?('ProfileDisplayName', installed_profile_name) && \
            !device_forcelist.include?(profile_name)
          end
          timeout node['cpe_workspaceone']['hubcli_timeout']
        end
      end
    end

    user_forcelist = node['cpe_workspaceone']['mdm_profiles']['profiles']['user_forced'] || []

    # Loop through the enforced user profiles and compare with available profiles from MDM
    enforced_user_ws1_profiles = node['cpe_workspaceone']['mdm_profiles']['profiles']['user']
    # Current version of hubcli API returns only DeviceProfiles, no such thing as UserProfiles, so we must be clever
    # here and just do intelligent checks.
    device_attributes['DeviceProfiles'].each do |ws1_profile|
      profile_name = ws1_profile['Name']
      profile_id = ws1_profile['Id'].to_s
      profile_version = ws1_profile['CurrentVersion'].to_s
      # WS1 dynamically creates the DisplayName by taking the Name of the profile and how many revisions have been
      # done in the console. To make this simpler on the chef admin, we will concatenate the strings.
      installed_profile_name = profile_name + '/V_' + profile_version
      # Because of user/device level profiles being in one array, we need the if statement outside of the execute block
      if enforced_user_ws1_profiles.include?(profile_name)
        execute "Sending #{profile_name} for user installation to Workspace One console" do
          command node.hubcli_cmd("profiles --install #{profile_id}")
          only_if { node.ws1_hubcli_exists } # non-gsub or guard will fail.
          not_if do
            node.user_profile_installed?('ProfileDisplayName', installed_profile_name) && \
            !user_forcelist.include?(profile_name)
          end
          timeout node['cpe_workspaceone']['hubcli_timeout']
        end
      end
    end
  end

  def install
    return unless node['cpe_workspaceone']['install']

    macos_install if macos?
  end

  def macos_install
    ws1_pkg_version = node['cpe_workspaceone']['pkg']['version']
    ws1_pkg_allow_downgrade = node['cpe_workspaceone']['pkg']['allow_downgrade']
    # Dumb workaround because WS1 Beta release versions contain a space.
    if ws1_pkg_version.include?(' ')
      Chef::Log.warn('cpe_workspaceone - package version contains a space! This is more than likely due to a beta '\
        'release. Forcing allow_downgrade to true to prevent Chef failures with cpe_remote.')
      ws1_pkg_allow_downgrade = true
    end

    cpe_remote_pkg 'Workspace One Agent' do
      allow_downgrade ws1_pkg_allow_downgrade
      app node['cpe_workspaceone']['pkg']['app_name']
      checksum node['cpe_workspaceone']['pkg']['checksum']
      pkg_name node['cpe_workspaceone']['pkg']['pkg_name'] if node['cpe_workspaceone']['pkg']['pkg_name']
      pkg_url node['cpe_workspaceone']['pkg']['pkg_url'] if node['cpe_workspaceone']['pkg']['pkg_url']
      receipt node['cpe_workspaceone']['pkg']['receipt']
      version ws1_pkg_version
      unless node['cpe_workspaceone']['pkg']['headers'].nil?
        headers node['cpe_workspaceone']['pkg']['headers']
      end
    end
  end

  def manage
    return unless node['cpe_workspaceone']['manage']

    macos_manage if macos?
  end

  def macos_manage
    ws1agent_prefs = node['cpe_workspaceone']['prefs'].compact
    unless ws1agent_prefs.empty?
      ws1agent_prefs.each_key do |key|
        next if ws1agent_prefs[key].nil?

        # WS1 agent doesn't use profiles atm. Chef 14+
        if node.at_least_chef14?
          macos_userdefaults "Configure com.vmware.hub.agent - #{key}" do
            domain '/Library/Preferences/com.vmware.hub.agent'
            key key
            value ws1agent_prefs[key]
          end
        end
      end
    end
  end

  def uninstall
    return unless node['cpe_workspaceone']['uninstall']

    macos_uninstall if macos?
  end

  def macos_uninstall
    # TODO: need to write
    return
  end
end
