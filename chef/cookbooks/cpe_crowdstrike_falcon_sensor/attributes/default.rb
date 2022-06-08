#
# Cookbook:: cpe_crowdstrike_falcon_sensor
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

default['cpe_crowdstrike_falcon_sensor'] = {
  'agent' => {
    'enable_network_filter' => true,
    'manage_network_filter' => false,
    'registration_token' => nil,
  },
  'install' => false,
  'grouping_tags' => nil,
  'manage' => false,
  'minimum_supported_version' => '6.25.13807.0',
  'pkg' => {
    'allow_downgrade' => true,
    'app_name' => nil,
    'checksum' => nil,
    'version' => nil,
    'args' => {
      'vdi' => false,
      'no_start' => false,
      'prov_no_wait' => false,
    },
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
  default['cpe_crowdstrike_falcon_sensor']['agent']['falcon_support_path'] =
    '/Library/Application Support/CrowdStrike/Falcon'
  default['cpe_crowdstrike_falcon_sensor']['agent']['falconctl_path'] =
    '/Applications/Falcon.app/Contents/Resources/falconctl'
  default['cpe_crowdstrike_falcon_sensor']['pkg']['mac_os_x_pkg_receipt'] =
    'com.crowdstrike.falcon.sensor.common'
when 'windows'
  default['cpe_crowdstrike_falcon_sensor']['pkg']['uninstall_checksum'] = nil
  default['cpe_crowdstrike_falcon_sensor']['pkg']['uninstall_version'] = nil
end
