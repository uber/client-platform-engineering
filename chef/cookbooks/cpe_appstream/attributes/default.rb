#
# Cookbook:: cpe_appstream
# Attributes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2022-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

default['cpe_appstream'] = {
  'install' => false,
  'image_assistant_path' => 'C:\\Program Files\\Amazon\\Photon\\ConsoleImageBuilder\\image-assistant.exe',
  'image_builder_tag' => nil,
  'applications' => [
    {
      'name' => nil,
      'display_name' => nil,
      'path' => nil,
      'working_dir' => nil,
      'manifest_path' => nil,
    },
  ],
  'image' => {
    'name' => nil,
    'description' => nil,
    'display_name' => nil,
    'enable_dynamic_app_catalog' => nil,
    'use_latest_agent_version' => nil,
    'tags' => {
      'Owner' => nil,
    },
  },
}
