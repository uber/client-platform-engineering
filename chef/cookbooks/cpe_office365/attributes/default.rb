#
# Cookbook:: cpe_office365
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

default['cpe_office365'] = {
  'install' => false,
  'uninstall' => false,
  'version' => nil,
  'bin' => {
    'bin_name' => nil,
    'checksum' => nil,
  },
  'config' => {
    'conf_name' => nil,
    'migrate_arch' => nil,
    'channel' => nil,
    'office_client_edition' => nil,
    'product_id' => nil,
    'shared_computer_licensing' => nil,
    'scl_cache_override' => nil,
    'auto_activate' => nil,
    'force_app_shutdown' => nil,
    'device_based_licensing' => nil,
    'updates_enabled' => nil,
    'company' => nil,
    'display_level' => nil,
    'accept_eula' => nil,
    'remove_all' => nil,
    'remove_msi' => nil,
    'match_os' => nil,
    'match_previous_msi' => nil,
    'exclude' => nil,
    'ignored_products' => [], # Products not included in uninstall
  },
  'catalog' => {
    'access' => false,
    'bing' => false,
    'excel' => false,
    'groove' => false,
    'lync' => false,
    'onenote' => false,
    'oneDrive' => false,
    'outlook' => false,
    'powerpoint' => false,
    'publisher' => false,
    'teams' => false,
    'word' => false,
  },
}
