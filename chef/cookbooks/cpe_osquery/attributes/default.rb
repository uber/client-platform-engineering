#
# Cookbook:: cpe_osquery
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

base_bin_path = value_for_platform_family(
  'mac_os_x' => '/opt/osquery/lib/osquery.app/Contents/MacOS',
  'debian' => '/opt/osquery/bin',
  'windows' => 'C:\Program Files\osquery',
)

osquery_dir = value_for_platform_family(
  'windows' => 'C:\Program Files\osquery',
  'debian' => '/opt/osquery/share/osquery',
  'mac_os_x' => '/var/osquery',
  'default' => nil,
)

osquery_ext_dir = value_for_platform_family(
  'windows' => 'C:\Program Files\osquery\extensions',
  'debian' => '/private/var/osquery/extensions',
  'mac_os_x' => '/var/osquery/extensions',
  'default' => nil,
)

default['cpe_osquery'] = {
  'base_bin_path' => base_bin_path,
  'conf' => {},
  'extensions' => {},
  'install' => false,
  'manage' => false,
  'manage_official_packs' => false,
  'official_packs_install_list' => [],
  'options' => {},
  'osquery_dir' => osquery_dir,
  'osquery_ext_dir' => osquery_ext_dir,
  'packs' => {},
  'pkg' => {
    'name' => nil,
    'checksum' => nil,
    'version' => nil,
    'receipt' => 'io.osquery.agent',
  },
  'uninstall' => false,
}
