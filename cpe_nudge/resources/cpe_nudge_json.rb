#
# Cookbook Name:: cpe_nudge
# Resources:: cpe_nudge_json
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_nudge_json
provides :cpe_nudge_json, :os => 'darwin'

default_action :manage

action :manage do
  install if install? && !uninstall?
end

action_class do
  def install?
    node['cpe_nudge']['manage_json']
  end

  def uninstall?
    node['cpe_nudge']['uninstall']
  end

  def label
    # This portion is taken from cpe_launchd. Since we use cpe_launchd to
    # create our launch agent, the label specified in the attributes will not
    # match the actual label/path that's created. Doing this will result in
    # the right file being targeted.
    label = node['cpe_nudge']['la_identifier']
    if label.start_with?('com')
      name = label.split('.')
      name.delete('com')
      label = name.join('.')
      label = "#{node['cpe_launchd']['prefix']}.#{label}"
    end
    label
  end

  def install
    # JSON
    json_path = node['cpe_nudge']['json_path']
    json_prefs = node['cpe_nudge']['json_prefs'].to_h.compact

    if json_prefs.empty? || json_prefs.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    # If we are updating nudge JSON, we need to disable the launch agent.
    # cpe_launchd will turn it back on later in the run so we don't have a
    # mismatch in what's loaded in memory and what's on disk
    file json_path do
      mode '0644'
      owner 'root'
      group 'wheel'
      action :create
      content Chef::JSONCompat.to_json_pretty(json_prefs)
      if ::File.exists?("/Library/LaunchAgents/#{label}.plist")
        notifies :disable, "launchd[#{label}]", :immediately
      end
    end

    # Triggered Launch Agent action
    launchd label do
      action :nothing
      type 'agent'
    end
  end
end
