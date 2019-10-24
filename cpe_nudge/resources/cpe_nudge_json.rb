#
# Cookbook:: cpe_nudge
# Resources:: cpe_nudge_json
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
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

  def install
    # JSON
    json_path = node['cpe_nudge']['json_path']
    json_prefs = node['cpe_nudge']['json_prefs'].to_h.reject { |_k, v| v.nil? }

    if json_prefs.empty? || json_prefs.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    file json_path do
      mode '0644'
      owner 'root'
      group 'wheel'
      action :create
      content Chef::JSONCompat.to_json_pretty(json_prefs)
    end
  end
end
