#
# Cookbook:: cpe_anyconnect
# Attributes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2021-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

default['cpe_anyconnect'] = {
  'desktop_shortcut' => false,
  'install' => false,
  'la_gui_identifier' => 'com.cisco.anyconnect.gui',
  'manage' => false,
  'modules' => [
    {
      'checksum' => nil,
      'display_name' => nil,
      'install_args' => nil,
      'name' => nil,
      'version' => nil,
    },
  ],
  'organization_id' => nil,
  'pkg' => {
    'allow_downgrade' => false,
    'app_name' => 'cisco_anyconnect',
    'cache_path' => Chef::Config[:file_cache_path],
    'checksum' => nil,
    'version' => nil,
  },
  'profile_identifier' => nil,
  'umbrella_diagnostic_link' => nil,
  'uninstall' => false,
}

case node['platform_family']
when 'mac_os_x'
  default['cpe_anyconnect']['app_path'] =
    '/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app'
  default['cpe_anyconnect']['pkg']['dart_receipt'] = 'com.cisco.pkg.anyconnect.dart'
  default['cpe_anyconnect']['pkg']['receipt'] = 'com.cisco.pkg.anyconnect.vpn'
  default['cpe_anyconnect']['pkg']['umbrella_receipt'] = 'com.cisco.pkg.anyconnect.umbrella'
  default['cpe_anyconnect']['cookbook']['cookbook_name'] = nil
  default['cpe_anyconnect']['cookbook']['template_source'] = nil
  default['cpe_anyconnect']['final_xml_path'] = nil
end
