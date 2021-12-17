#
# Cookbook:: cpe_umad
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

default['cpe_umad'] = {
  'install' => false,
  'uninstall' => false,
  'python_path' => '/Library/umad/Python.framework',
  'shebang' => '#!/Library/umad/Python.framework/Versions/3.8/bin/python3',
  'custom_resources' => false,
  'manage_agents' => false,
  'la' => {
    'limit_load_to_session_type' => [
      'Aqua',
    ],
    'program_arguments' => [
      '/Library/umad/Resources/umad',
    ],
    'run_at_load' => true,
    'standard_out_path' => '/Library/umad/Logs/umad.log',
    'standard_error_path' => '/Library/umad/Logs/umad.log',
    'start_calendar_interval' => [
      {
        'Minute' => 0,
      },
      {
        'Minute' => 30,
      },
    ],
    'type' => 'agent',
  },
  'la_identifier' => 'com.erikng.umad',
  'ld_dep' => {
    'keep_alive' => {
      'PathState' => {
        '/var/tmp/umad/.check_dep_record' => true,
      },
    },
    'program_arguments' => [
      '/Library/umad/Resources/umad_check_dep_record',
    ],
    'on_demand' => true,
    'type' => 'daemon',
  },
  'ld_dep_identifier' => 'com.erikng.umad.check_dep_record',
  'ld_nag' => {
    'keep_alive' => {
      'PathState' => {
        '/var/tmp/umad/.trigger_nag' => true,
      },
    },
    'program_arguments' => [
      '/Library/umad/Resources/umad_trigger_nag',
    ],
    'on_demand' => true,
    'type' => 'daemon',
  },
  'ld_nag_identifier' => 'com.erikng.umad.trigger_nag',
}
