#
# Cookbook Name:: cpe_zoom
# Resources:: cpe_zoom
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_zoom
default_action :run

# Enforce Zoom Settings
action :run do
  zoom_prefs = node['cpe_zoom'].reject { |_k, v| v.nil? }
  prefix = node['cpe_profiles']['prefix']
  organization = node['organization'] || 'Uber'
  zoom_profile = {
    'PayloadIdentifier' => "#{prefix}.zoom",
    'PayloadRemovalDisallowed' => true,
    'PayloadScope' => 'System',
    'PayloadType' => 'Configuration',
    'PayloadUUID' => 'B1B0DEED-DC7C-4122-912F-A22F660DF53D',
    'PayloadOrganization' => organization,
    'PayloadVersion' => 1,
    'PayloadDisplayName' => 'Zoom',
    'PayloadContent' => [],
  }
  unless zoom_prefs.empty?
    zoom_profile['PayloadContent'].push(
      'PayloadType' => 'us.zoom.config',
      'PayloadVersion' => 1,
      'PayloadIdentifier' => "#{prefix}.zoom",
      'PayloadUUID' => 'B976C3E1-B59D-4060-80DA-13A42270D1E7',
      'PayloadEnabled' => true,
      'PayloadDisplayName' => 'Zoom',
    )
    zoom_prefs.each_key do |key|
      next if zoom_prefs[key].nil?
      zoom_profile['PayloadContent'][0][key] = zoom_prefs[key]
      # Double tap the preferences since Zoom doesn't use profiles atm. Chef 14+
      if node.at_least_chef14?
        macos_userdefaults "Configure us.zoom.config - #{key}" do
          domain '/Library/Preferences/us.zoom.config'
          key key
          value zoom_prefs[key]
        end
      end
    end
  end

  node.default['cpe_profiles']["#{prefix}.zoom"] = zoom_profile
end
