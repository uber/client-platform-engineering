#
# Cookbook Name:: cpe_nudge
# Attributes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

default['cpe_nudge'] = {
  'install' => false,
  'uninstall' => false,
  'python_path' => '/Library/nudge/Python.framework',
  'shebang' => '#!/Library/nudge/Python.framework/Versions/3.8/bin/python3',
  'custom_resources' => false,
  'json_path' => '/Library/nudge/Resources/nudge.json',
  'json_prefs' => {
    'preferences' => nil,
    'software_updates' => nil,
  },
  'manage_json' => false,
  'manage_la' => false,
  'la' => {
    'limit_load_to_session_type' => [
      'Aqua',
    ],
    'program_arguments' => [
      '/Library/nudge/Resources/nudge',
    ],
    'run_at_load' => true,
    'standard_out_path' => '/Library/nudge/Logs/nudge.log',
    'standard_error_path' =>
      '/Library/nudge/Logs/nudge.log',
    'start_calendar_interval' => [
      {
        'Minute' => 15,
      },
      {
        'Minute' => 45,
      },
    ],
    'type' => 'agent',
  },
  'la_identifier' => 'com.erikng.nudge',
}
