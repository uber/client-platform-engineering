#
# Cookbook:: cpe_chefclient
# Attribute:: default
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

chefdir = value_for_platform_family(
  'windows' => 'C:\chef',
  'default' => '/etc/chef',
)

default['cpe_chefclient'] = {
  'configure' => false,
  'unmanage' => false,
  'path' => chefdir,
  'run_list' => {},
  'config' => {},
}
