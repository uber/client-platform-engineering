#
# Cookbook:: cpe_nudge
# Resources:: cpe_nudge_python_launchagent
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

resource_name :cpe_nudge_python_launchagent
provides :cpe_nudge_python_launchagent, :os => 'darwin'

default_action :manage

action :manage do
  install if install? && !uninstall?
end

action_class do
  def install?
    node['cpe_nudge']['nudge-python']['manage_launchagent']
  end

  def uninstall?
    node['cpe_nudge']['nudge-python']['uninstall']
  end

  def install
    unless ::File.exists?(node['cpe_nudge']['nudge-python']['python_path'])
      Chef::Log.warn("Python defined in node['cpe_nudge']['nudge-python']['python_path'] is not installed.")
      return
    end

    # Launch Agent
    launchagent_identifier = node['cpe_nudge']['nudge-python']['launchagent_identifier']
    node.default['cpe_launchd'][launchagent_identifier] =
      node.default['cpe_nudge']['nudge-python']['launchagent']
  end
end
