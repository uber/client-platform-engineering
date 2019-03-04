#
# Cookbook Name:: cpe_nudge
# Resources:: cpe_nudge_la
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_nudge_la
provides :cpe_nudge_la, :os => 'darwin'
default_action :manage

action :manage do
  install if install? && !uninstall?
end

action_class do
  def install?
    node['cpe_nudge']['manage_la']
  end

  def uninstall?
    node['cpe_nudge']['uninstall']
  end

  def install
    # Launch Agent
    la_identifier = node['cpe_nudge']['la_identifier']
    node.default['cpe_launchd'][la_identifier] =
      node.default['cpe_nudge']['la']
  end
end
