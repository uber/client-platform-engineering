#
# Cookbook:: cpe_sal
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

gosal_dir = value_for_platform_family(
  'mac_os_x' => 'nil',
  'debian' => '/var/lib/gosal',
  'windows' => 'C:\\gosal',
)

default['cpe_sal'] = {
  'config' => {
    'BasicAuth' => nil,
    'CACert' => nil,
    'GetGrains' => nil,
    'GetOhai' => nil,
    'key' => nil,
    'management' => nil,
    'NameType' => nil,
    'OhaiClientConfigPath' => nil,
    'ServerURL' => nil,
    'SkipFacts' => nil,
    'SSLClientCertificate' => nil,
    'SSLClientKey' => nil,
    'SyncScripts' => nil,
  },
  'configure' => false,
  'gosal_dir' => gosal_dir,
  'install' => false,
  'manage_plugins' => false,
  'plugins' => {},
  'scripts_pkg' => {
    'name' => nil,
    'version' => nil,
    'checksum' => nil,
    'receipt' => nil,
    'url' => nil,
  },
  'task' => {
    'minutes_per_run' => 30,
    'seconds_random_delay' => '1200', # must be a string
  },
}
