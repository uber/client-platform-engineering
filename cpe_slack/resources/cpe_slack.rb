#
# Cookbook Name:: cpe_slack
# Resources:: cpe_slack
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2020-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_slack
provides :cpe_slack, :os => 'darwin'

default_action :config

# Enforce Slack Settings
action :config do
  slack_prefs = node['cpe_slack'].reject { |_k, v| v.nil? }
  if slack_prefs.empty?
    Chef::Log.info("#{cookbook_name}: No prefs found.")
    return
  end
  prefix = node['cpe_profiles']['prefix']
  organization = node['organization'] || 'Uber'
  slack_profile = {
    'PayloadIdentifier' => "#{prefix}.slack",
    'PayloadRemovalDisallowed' => true,
    'PayloadScope' => 'System',
    'PayloadType' => 'Configuration',
    'PayloadUUID' => '063EE72F-E58C-46DB-AC68-A76F09676DE3',
    'PayloadOrganization' => organization,
    'PayloadVersion' => 1,
    'PayloadDisplayName' => 'Slack',
    'PayloadContent' => [],
  }
  unless slack_prefs.empty?
    slack_profile['PayloadContent'].push(
      'PayloadType' => 'com.tinyspeck.slackmacgap',
      'PayloadVersion' => 1,
      'PayloadIdentifier' => "#{prefix}.slack",
      'PayloadUUID' => '2B098882-100B-4FE6-B1C8-24F33BD30672',
      'PayloadEnabled' => true,
      'PayloadDisplayName' => 'Slack',
    )
  end

  slack_prefs.each_key do |key|
    next if slack_prefs[key].nil?
    slack_profile['PayloadContent'][0][key] = slack_prefs[key]
  end

  node.default['cpe_profiles']["#{prefix}.slack"] = slack_profile
end
