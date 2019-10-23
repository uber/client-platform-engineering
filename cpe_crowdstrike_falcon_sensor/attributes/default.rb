#
# Cookbook Name:: cpe_crowdstrike_falcon_sensor
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

default['cpe_crowdstrike_falcon_sensor'] = {
  'agent' => {
    'registration_token' => nil,
  },
  'install' => false,
  'manage' => false,
  'pkg' => {
    'allow_downgrade' => true,
    'app_name' => nil,
    'checksum' => nil,
    'version' => nil,
  },
  'uninstall' => false,
}

case node['platform_family']
when 'debian'
  default['cpe_crowdstrike_falcon_sensor']['agent']['customer_id'] = nil
  default['cpe_crowdstrike_falcon_sensor']['agent']['falconctl_path'] =
    '/opt/CrowdStrike/falconctl'
  default['cpe_crowdstrike_falcon_sensor']['pkg']['dpkg_version'] = nil
when 'mac_os_x'
  default['cpe_crowdstrike_falcon_sensor']['agent']['falconctl_path'] =
    '/Library/CS/falconctl'
  default['cpe_crowdstrike_falcon_sensor']['pkg']['mac_os_x_pkg_receipt'] =
    'com.crowdstrike.falcon.sensor'
when 'windows'
  default['cpe_crowdstrike_falcon_sensor']['pkg']['uninstall_checksum'] = nil
  default['cpe_crowdstrike_falcon_sensor']['pkg']['uninstall_version'] = nil
end
