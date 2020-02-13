#
# Cookbook Name:: cpe_workspaceone
# Resources:: cpe_workspaceone
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_workspaceone
provides :cpe_workspaceone
default_action :manage

action :manage do
  # manage needs to go first if you are attempting to hide the agent from appearing showing it's UX to users.
  manage if manage?
  install if install?
  enforce_mdm_profiles if enforce_mdm_profiles?
  uninstall if !install? && uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def enforce_mdm_profiles?
    node['cpe_workspaceone']['mdm_profiles']['enforce']
  end

  def install?
    node['cpe_workspaceone']['install']
  end

  def manage?
    node['cpe_workspaceone']['manage']
  end

  def uninstall?
    node['cpe_workspaceone']['uninstall']
  end

  def enforce_mdm_profiles
    return unless node['cpe_workspaceone']['mdm_profiles']['enforce']
    macos_enforce_mdm_profiles if node.macos?
  end

  def macos_enforce_mdm_profiles
    # Bail if path doesn't exist
    unless node.ws1_hubcli_exists
      Chef::Log.warn('cpe_workspaceone - hubcli path does not exist, cannot enforce MDM profiles!')
      return
    end

    # Bail if there are no device attributes
    device_attributes = node.ws1_device_attributes
    return if device_attributes.empty? || device_attributes.nil?

    hubcli_path = node['cpe_workspaceone']['hubcli_path']

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
          # spaces in path, so we need to convert them with gsub
          command "#{hubcli_path.gsub(/ /, '\ ')} profiles --install #{profile_id}"
          only_if { node.ws1_hubcli_exists } # non-gsub or guard will fail.
          not_if { node.profile_installed?('ProfileDisplayName', installed_profile_name) }
          # Only wait two mintues for this command to finish, because something may be up
          timeout 120
        end
      end
    end

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
          # spaces in path, so we need to convert them with gsub
          command "#{hubcli_path.gsub(/ /, '\ ')} profiles --install #{profile_id}"
          only_if { node.ws1_hubcli_exists } # non-gsub or guard will fail.
          not_if { node.user_profile_installed?('ProfileDisplayName', installed_profile_name) }
        end
      end
    end
  end

  def install
    return unless node['cpe_workspaceone']['install']
    macos_install if node.macos?
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
    end
  end

  def manage
    return unless node['cpe_workspaceone']['manage']
    macos_manage if node.macos?
  end

  def macos_manage
    ws1agent_prefs = node['cpe_workspaceone']['prefs'].reject { |_k, v| v.nil? }
    prefix = node['cpe_profiles']['prefix']
    organization = node['organization'] || 'Uber'
    ws1agent_profile = {
      'PayloadIdentifier' => "#{prefix}.ws1",
      'PayloadRemovalDisallowed' => true,
      'PayloadScope' => 'System',
      'PayloadType' => 'Configuration',
      'PayloadUUID' => '605A10E6-9068-4DAA-9AE0-5334E4D49143',
      'PayloadOrganization' => organization,
      'PayloadVersion' => 1,
      'PayloadDisplayName' => 'Workspace One',
      'PayloadContent' => [],
    }
    unless ws1agent_prefs.empty?
      ws1agent_profile['PayloadContent'].push(
        'PayloadType' => 'com.vmware.hub.agent',
        'PayloadVersion' => 1,
        'PayloadIdentifier' => "#{prefix}.ws1",
        'PayloadUUID' => 'A37C4F5A-07F8-4E66-BA20-9EB808EB3E3D',
        'PayloadEnabled' => true,
        'PayloadDisplayName' => 'Workspace One',
      )
      ws1agent_prefs.each_key do |key|
        next if ws1agent_prefs[key].nil?
        ws1agent_profile['PayloadContent'][0][key] = ws1agent_prefs[key]
        # Double tap the preferences since WS1 agent doesn't use profiles atm. Chef 14+
        if node.at_least?(node['chef_packages']['chef']['version'], '14.0.0')
          macos_userdefaults "Configure com.vmware.hub.agent - #{key}" do
            domain '/Library/Preferences/com.vmware.hub.agent'
            key key
            value ws1agent_prefs[key]
          end
        end
      end
    end
    node.default['cpe_profiles']["#{prefix}.ws1"] = ws1agent_profile
  end

  def uninstall
    return unless node['cpe_workspaceone']['uninstall']
    macos_uninstall if node.macos?
  end

  def macos_uninstall
    # TODO: need to write
    return
  end
end
