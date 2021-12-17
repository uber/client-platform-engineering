#
# Cookbook:: cpe_ulimit
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

default['cpe_ulimit'] = {
  'manage' => false,
  # run /bin/launchctl limit to get these default values. Tested on 10.14
  'maxfiles_soft_limit' => nil, # Apple's default '256'
  'maxfiles_hard_limit' => nil, # Apple's default 'unlimited' or '10240'
  'maxproc_soft_limit' => nil, # looks to be dynamic based on RAM
  'maxproc_hard_limit' => nil, # Apple's default 'unlimited' or '4256'
  'sysctl_maxfiles' => nil, # No idea what apple's default is.
}
