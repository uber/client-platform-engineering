#
# Cookbook:: cpe_nudge
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

default['cpe_nudge'] = {
  'nudge-python' => {
    'base_path' => '/Library/nudge',
    'custom_resources' => false,
    'install' => false,
    'json_path' => '/Library/nudge/Resources/nudge.json',
    'json_prefs' => {
      'preferences' => nil,
      'software_updates' => nil,
    },
    'launchagent' => {
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
          'Minute' => 0,
        },
        {
          'Minute' => 30,
        },
      ],
      'type' => 'agent',
    },
    'launchagent_identifier' => 'com.erikng.nudge',
    'manage_json' => false,
    'manage_launchagent' => false,
    'python_path' => '/Library/ManagedFrameworks/Python/Python3.framework',
    'uninstall' => false,
  },
  'nudge-swift' => {
    'app_path' => '/Applications/Utilities/Nudge.app',
    'base_path' => '/Library/Application Support/Nudge',
    'custom_resources' => false,
    'install' => false,
    'json_path' => '/Library/Preferences/com.github.macadmins.Nudge.json',
    'json_prefs' => {
      'optionalFeatures' => nil,
      'osVersionRequirements' => nil,
      'userExperience' => nil,
      'userInterface' => nil,
    },
    'launchagent' => {
      'limit_load_to_session_type' => [
        'Aqua',
      ],
      'program_arguments' => [
        '/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge',
      ],
      'run_at_load' => true,
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
    'launchagent_identifier' => 'com.github.macadmins.Nudge',
    'loggerdaemon' => {
      'program_arguments' => [
        '/usr/bin/log',
        'stream',
        '--predicate',
        "subsystem == \'com.github.macadmins.Nudge\'",
        '--style',
        'syslog',
        '--color',
        'none',
      ],
      'run_at_load' => true,
      'standard_out_path' => '/var/log/Nudge.log',
      'type' => 'daemon',
    },
    'loggerdaemon_identifier' => 'com.github.macadmins.Nudge.Logger',
    'manage_json' => false,
    'manage_launchagent' => false,
    'manage_loggerdaemon' => false,
    'manage_pkg' => false,
    'pkg' => {
      'allow_downgrade' => false,
      'app_name' => 'Nudge',
      'checksum' => nil,
      'receipt' => 'com.github.macadmins.Nudge',
      'url' => nil,
      'version' => nil,
    },
    'uninstall' => false,
  },
}
