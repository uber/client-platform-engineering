#
# Cookbook Name:: cpe_anyconnect
# Attributes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2021-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

default['cpe_anyconnect'] = {
  'install' => false,
  'la_gui_identifier' => 'com.cisco.anyconnect.gui',
  'manage' => false,
  'pkg' => {
    'allow_downgrade' => false,
    'app_name' => 'cisco_anyconnect',
    'cache_path' => Chef::Config[:file_cache_path],
    'checksum' => nil,
    'version' => nil,
  },
  'uninstall' => false,
}

case node['platform_family']
when 'mac_os_x'
  default['cpe_anyconnect']['app_path'] =
    '/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app'
  default['cpe_anyconnect']['pkg']['receipt'] = 'com.cisco.pkg.anyconnect.vpn'
end
