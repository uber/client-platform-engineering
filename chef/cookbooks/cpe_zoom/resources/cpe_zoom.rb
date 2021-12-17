#
# Cookbook:: cpe_zoom
# Resources:: cpe_zoom
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

resource_name :cpe_zoom
provides :cpe_zoom, :os => 'darwin'

default_action :run

# Enforce Zoom Settings
action :run do
  zoom_prefs = node['cpe_zoom'].compact
  unless zoom_prefs.empty?
    zoom_prefs.each_key do |key|
      next if zoom_prefs[key].nil?

      # Zoom doesn't use profiles atm. Chef 14+
      if node.at_least_chef14?
        macos_userdefaults "Configure us.zoom.config - #{key}" do
          domain '/Library/Preferences/us.zoom.config'
          key key
          value zoom_prefs[key]
        end
      end
    end
  end
end
