#
# Cookbook:: cpe_apple_caching
# Resources:: cpe_apple_caching
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

resource_name :cpe_apple_caching
provides :cpe_apple_caching, :os => 'darwin'

default_action :manage

action :manage do
  configure
  force_disable
end

action_class do
  def configure
    return unless node['cpe_apple_caching']['configure']

    # Get info about caching config, rejecting unset values
    caching_prefs = node['cpe_apple_caching']['prefs'].compact
    if caching_prefs.empty? || caching_prefs.nil?
      Chef::Log.warn('caching config is not populated, skipping configuration')
      return
    end
    configure_profile(caching_prefs)
  end

  def configure_profile(caching_prefs)
    # Build configuration profile and pass it to cpe_profiles
    prefix = node['cpe_profiles']['prefix']
    organization = node['organization'] ? node['organization'] : 'Uber' # rubocop:disable Style/UnneededCondition
    acc_profile = {
      'PayloadIdentifier' => "#{prefix}.content_caching",
      'PayloadRemovalDisallowed' => true,
      'PayloadScope' => 'System',
      'PayloadType' => 'Configuration',
      'PayloadUUID' => 'C44FA628-5184-4EB2-9A96-8B5B5A40C060',
      'PayloadOrganization' => organization,
      'PayloadVersion' => 1,
      'PayloadDisplayName' => 'Content Caching',
      'PayloadContent' => [],
    }
    acc_profile['PayloadContent'].push(
      'PayloadType' => 'com.apple.AssetCache.managed',
      'PayloadVersion' => 1,
      'PayloadIdentifier' => "#{prefix}.content_caching",
      'PayloadUUID' => '5F75A1B7-C3EB-47E0-9C99-F29A710EE367',
      'PayloadEnabled' => true,
      'PayloadDisplayName' => 'Content Caching',
    )
    caching_prefs.each do |k, v|
      acc_profile['PayloadContent'][0][k] = v
    end

    node.default['cpe_profiles']["#{prefix}.content_caching"] = acc_profile
  end

  def force_disable
    return unless node['cpe_apple_caching']['force_disable']

    execute 'Force disabling Apple Content Caching' do
      command '/usr/bin/AssetCacheManagerUtil deactivate'
      only_if { check_caching_status.include?('true') }
    end
  end

  def check_caching_status
    # Blank strings for our comparisons vs nil because of our guards.
    status = ''
    cmd_string = '/usr/bin/AssetCacheManagerUtil isActivated --json'
    cmd = shell_out(cmd_string).stdout.to_s
    if cmd.nil? || cmd.empty?
      return status
    else
      status = cmd.chomp
    end

    status
  end
end
