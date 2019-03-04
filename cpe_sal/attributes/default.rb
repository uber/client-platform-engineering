#
# Cookbook Name:: cpe_sal
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

default['cpe_sal'] = {
  'install' => false,
  'scripts_pkg' => {
    'name' => nil,
    'version' => nil,
    'checksum' => nil,
    'receipt' => nil,
    'url' => nil,
  },
  'configure' => false,
  'config' => {
    'ServerURL' => nil,
    'key' => nil,
    'BasicAuth' => nil,
    'SyncScripts' => nil,
    'SkipFacts' => nil,
    'GetGrains' => nil,
    'GetOhai' => nil,
    'OhaiClientConfigPath' => nil,
    'CACert' => nil,
    'SSLClientCertificate' => nil,
    'SSLClientKey' => nil,
    'NameType' => nil,
  },
  'manage_plugins' => false,
  'plugins' => {},
}
