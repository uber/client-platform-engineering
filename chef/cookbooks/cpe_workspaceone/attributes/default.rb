#
# Cookbook:: cpe_workspaceone
# Attributes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

default['cpe_workspaceone'] = {
  'cache_invalidation' => 7200, # seconds, 2 hours
  'hubcli_path' => '/Applications/Workspace ONE Intelligent Hub.app/Contents/Resources/'\
  'IntelligentHubAgent.app/Contents/Resources/cli/hubcli',
  'hubcli_timeout' => 300,
  'install' => false,
  'manage' => false,
  'manage_cli' => false,
  'mdm_profiles' => {
    'enforce' => false,
    'profiles' => {
      'device' => [],
      'user' => [],
      'user_forced' => [],
      'device_forced' => [],
    },
  },
  'pkg' => {
    'allow_downgrade' => false,
    'app_name' => 'workspace_one_intelligent_hub',
    'checksum' => nil,
    'pkg_name' => nil,
    'pkg_url' => nil,
    'receipt' => 'com.air-watch.pkg.OSXAgent',
    'version' => nil,
    'headers' => nil,
  },
  'prefs' => {
    'HubAgentIconVisiblePreference' => nil,
  },
  'uninstall' => false,
  'use_cache' => true,
  'cli_prefs' => {
    'checkin-interval' => 60,
    'menubar-icon' => true,
    'sample-interval' => 60,
    'transmit-interval' => 60,
  },
}
