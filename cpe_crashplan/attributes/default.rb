#
# Cookbook Name:: cpe_crashplan
# Attributes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

return unless node.macos?

base_dir = value_for_platform_family(
  'mac_os_x' => '/Library/Application Support/CrashPlan',
  'windows' => 'C:\\ProgramData\\CrashPlan',
)

uninstall_script = value_for_platform_family(
  'mac_os_x' => ::File.join(
    base_dir,
    'Uninstall.app/Contents/Resources/uninstall.sh',
  ),
  'windows' => nil,
)

default['cpe_crashplan'] = {
  'install' => false,
  'uninstall' => false,
  'prevent_downgrades' => false,
  'preserve_guid_on_upgrade' => true,
  'use_custom_files' => false,
  'uninstall_script' => uninstall_script,
  'identity_file' => ::File.join(base_dir, '.identity'),
  'pkg' => {
    'base_path' => base_dir,
    'app_name' => 'crashplan',
    'mac_os_x_pkg_receipt' => 'com.crashplan.app.pkg',
    'version' => nil,
    'checksum' => nil,
  },
  'config' => {
    'url' => nil,
    'policy_token' => nil,
    'ssl_whitelist' => nil,
  },
  'custom_files' => {
  },
}
