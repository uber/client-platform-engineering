#
# Cookbook:: cpe_nudge
# Resources:: cpe_nudge_swift_launchagent
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

resource_name :cpe_nudge_swift_launchctl
provides :cpe_nudge_swift_launchctl, :os => 'darwin'

default_action :manage

action :manage do
  manage_launchagent if manage_launchagent? && !uninstall?
  manage_loggerdaemon if manage_loggerdaemon? && !uninstall?
end

action_class do
  def manage_launchagent?
    node['cpe_nudge']['nudge-swift']['manage_launchagent']
  end

  def manage_loggerdaemon?
    node['cpe_nudge']['nudge-swift']['manage_loggerdaemon']
  end

  def uninstall?
    node['cpe_nudge']['nudge-swift']['uninstall']
  end

  def manage_launchagent
    if ::File.exists?(node['cpe_nudge']['nudge-swift']['app_path'])
      launchagent_identifier = node['cpe_nudge']['nudge-swift']['launchagent_identifier']
      node.default['cpe_launchd'][launchagent_identifier] =
        node['cpe_nudge']['nudge-swift']['launchagent']
    end
  end

  def manage_loggerdaemon
    if ::File.exists?(node['cpe_nudge']['nudge-swift']['app_path'])
      loggerdaemon_identifier = node['cpe_nudge']['nudge-swift']['loggerdaemon_identifier']
      node.default['cpe_launchd'][loggerdaemon_identifier] =
        node['cpe_nudge']['nudge-swift']['loggerdaemon']
    end
  end
end
