#
# Cookbook:: cpe_environment
# Attributes:: default
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

default['cpe_environment'] = {
  'manage' => false,
  'config' => {
    'paths' => [],
    'vars' => {},
  },
}
