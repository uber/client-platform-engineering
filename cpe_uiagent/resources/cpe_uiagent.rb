#
# Cookbook Name:: cpe_uiagent
# Resources:: cpe_uiagent
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_uiagent
default_action :run

action :run do
  uiagent_prefs = node['cpe_uiagent'].reject { |_k, v| v.nil? }
  if uiagent_prefs.empty?
    Chef::Log.info("#{cookbook_name}: No prefs found.")
    return
  end

  prefix = node['cpe_profiles']['prefix']
  organization = node['organization'] ? node['organization'] : 'Uber'
  uiagent_profile = {
    'PayloadIdentifier' => "#{prefix}.uiagent",
    'PayloadRemovalDisallowed' => true,
    'PayloadScope' => 'System',
    'PayloadType' => 'Configuration',
    'PayloadUUID' => '71941C69-1289-4945-B3B5-08AB18BC62D3',
    'PayloadOrganization' => organization,
    'PayloadVersion' => 1,
    'PayloadDisplayName' => 'CoreServices UI Agent',
    'PayloadContent' => [],
  }
  unless uiagent_prefs.empty?
    uiagent_profile['PayloadContent'].push(
      'PayloadType' => 'com.apple.coreservices.uiagent',
      'PayloadVersion' => 1,
      'PayloadIdentifier' => "#{prefix}.uiagent",
      'PayloadUUID' => '982D019B-5E1C-435F-9A8B-89615B72E932',
      'PayloadEnabled' => true,
      'PayloadDisplayName' => 'CoreServices UI Agent',
    )
    uiagent_prefs.each_key do |key|
      next if uiagent_prefs[key].nil?
      uiagent_profile['PayloadContent'][0][key] = uiagent_prefs[key]
    end
  end

  node.default['cpe_profiles']["#{prefix}.uiagent"] = uiagent_profile
end
