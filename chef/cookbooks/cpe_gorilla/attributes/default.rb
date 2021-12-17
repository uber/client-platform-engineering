#
# Cookbook:: cpe_gorilla
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

default['cpe_gorilla'] = {
  'dir' => 'C:\\ProgramData\\gorilla',
  'exe' => {
    'checksum' => nil,
    'name' => nil, # gorilla
    'version' => nil, # 1.0.0b2
  },
  'install' => false,
  'preferences' => {},
  'task' => {
    'create_task' => true,
    'minutes_per_run' => 30,
    'seconds_random_delay' => '1200', # must be a string
  },
  'uninstall' => false,
  'local_manifest' => {},
}
