#
# Cookbook:: cpe_nudge
# Resources:: cpe_nudge_swift_json
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2021-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_nudge_swift_json
provides :cpe_nudge_swift_json, :os => 'darwin'

default_action :manage

action :manage do
  manage_json if manage_json? && !uninstall?
end

action_class do
  def manage_json?
    node['cpe_nudge']['nudge-swift']['manage_json']
  end

  def uninstall?
    node['cpe_nudge']['nudge-swift']['uninstall']
  end

  def launchagent_label
    node.nudge_launchctl_label('swift', 'launchagent_identifier')
  end

  def launchagent_path
    node.nudge_launchctl_path('swift', 'launchagent_identifier')
  end

  def manage_json
    json_path = node['cpe_nudge']['nudge-swift']['json_path']
    json_prefs = node['cpe_nudge']['nudge-swift']['json_prefs'].to_h.compact

    if json_prefs.empty? || json_prefs.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    # If we are updating nudge JSON, we need to disable the launch agent.
    # cpe_launchd will turn it back on later in the run so we don't have a
    # mismatch in what's loaded in memory and what's on disk
    file json_path do
      mode '0644'
      owner root_owner
      group node['root_group']
      content Chef::JSONCompat.to_json_pretty(json_prefs.sort.to_h)
      notifies :disable, "launchd[#{launchagent_label}]", :immediately if ::File.exists?(launchagent_path)
      only_if { ::Dir.exists?(node['cpe_nudge']['nudge-swift']['app_path']) }
    end

    # Triggered Launch Agent action
    launchd launchagent_label do
      action :nothing
      type 'agent'
    end
  end
end
