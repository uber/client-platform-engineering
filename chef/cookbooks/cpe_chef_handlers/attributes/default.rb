#
# Cookbook:: cpe_chef_handlers
# Attribute:: default
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

paths = value_for_platform_family(
  'windows' => {
    'configdir' => 'C:\chef\client.d',
    'handlerdir' => 'C:\chef\handlers',
  },
  'default' => {
    'configdir' => '/etc/chef/client.d',
    'handlerdir' => '/etc/chef/handlers',
  },
)

default['cpe_chef_handlers'] = {
  'configure' => false,
  'remove' => false,
  'paths' => paths,
  'configs' => {},
}
