#
# Cookbook:: cpe_umad
# Resources:: cpe_umad_agents
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

resource_name :cpe_umad_agents
provides :cpe_umad_agents, :os => 'darwin'

default_action :manage

action :manage do
  install if install?
end

action_class do
  def install?
    node['cpe_umad']['manage_agents']
  end

  def install
    # Launch Agent
    la_identifier = node['cpe_umad']['la_identifier']
    node.default['cpe_launchd'][la_identifier] =
      node.default['cpe_umad']['la']

    # Launch Daemon (Check DEP Record)
    ld_dep_identifier = node['cpe_umad']['ld_dep_identifier']
    node.default['cpe_launchd'][ld_dep_identifier] =
      node.default['cpe_umad']['ld_dep']

    # Launch Daemon (Trigger Nag)
    ld_nag_identifier = node['cpe_umad']['ld_nag_identifier']
    node.default['cpe_launchd'][ld_nag_identifier] =
      node.default['cpe_umad']['ld_nag']
  end
end
