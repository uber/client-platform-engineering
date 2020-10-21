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
default_action :config

action_class do
  def set_signin_token(token)
    path = "/Users/#{node.console_user}/Library/Application Support/Slack"

    return false if node.console_user.nil?
    return false unless ::File.directory?(path)

    contents = { "default_signin_team" => token }.to_json

    file "#{path}/Signin.slacktoken" do
      content contents
      owner node.console_user
    end
  end
end

# Enforce Slack Settings
action :config do
  slack_prefs = node['cpe_slack']['preferences'].reject { |_k, v| v.nil? }
  signin_token = node['cpe_slack']['signin_token']
  if slack_prefs.empty? && signin_token.nil?
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

  unless signin_token.nil?
    set_signin_token(signin_token)
  end

  node.default['cpe_profiles']["#{prefix}.slack"] = slack_profile
end
