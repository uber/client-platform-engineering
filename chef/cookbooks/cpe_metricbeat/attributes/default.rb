#
# Cookbook:: cpe_metricbeat
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

metricbeat_dir = value_for_platform_family(
  'windows' => 'C:\ProgramData\metricbeat',
  'default' => '/opt/metricbeat',
)

metricbeat_bin = value_for_platform_family(
  'windows' => 'metricbeat.exe',
  'default' => 'metricbeat',
)

default['cpe_metricbeat'] = {
  'dir' => metricbeat_dir,
  'bin' => metricbeat_bin,
  'install' => false,
  'zip_info' => {
    'debian' => {
      'version' => nil,
      'checksum' => nil,
    },
    'windows' => {
      'version' => nil,
      'checksum' => nil,
    },
    'mac_os_x' => {
      'version' => nil,
      'checksum' => nil,
    },
  },
  'configure' => false,
  'config' => {},
}
