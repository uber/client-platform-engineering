#
# Cookbook:: cpe_apple_caching
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

default['cpe_apple_caching'] = {
  'prefs' => {
    'AllowPersonalCaching' => nil, # bool
    'AllowSharedCaching' => nil, # bool
    'AutoActivation' => nil, # bool
    'CacheLimit' => nil, # int
    'DataPath' => nil, # string
    'DenyTetheredCaching' => nil, # bool
    'ListenRanges' => nil, # array of dicts
    'ListenRangesOnly' => nil, # bool
    'ListenWithPeersAndParents' => nil, # bool
    'LocalSubnetsOnly' => nil, # bool
    'LogClientIdentity' => nil, # bool
    'Parents' => nil, # array of strings
    'ParentSelectionPolicy' => nil, # string
    'PeerFilterRanges' => nil, # array of dicts
    'PeerListenRanges' => nil, # array of dicts
    'PeerLocalSubnetsOnly' => nil, # bool
    'Port' => nil, # int
    'PublicRanges' => nil, # array of dicts
  },
  'configure' => false,
  'force_disable' => false,
}
