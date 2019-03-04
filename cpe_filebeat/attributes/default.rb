#
# Cookbook Name:: cpe_filebeat
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

datadir = value_for_platform_family(
  'windows' => 'C:\ProgramData',
  'default' => '/opt',
)
installdir = value_for_platform_family(
  'windows' => 'C:\Program Files',
  'default' => '/opt',
)

default['cpe_filebeat'] = {
  'datadir' => datadir,
  'installdir' => installdir,
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
