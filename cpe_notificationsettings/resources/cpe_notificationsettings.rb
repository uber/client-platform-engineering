# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Cookbook:: cpe_notificationsettings
# Resources:: cpe_notificationsettings
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

resource_name :cpe_notificationsettings
default_action :config

action :config do
  notify_prefs = node['cpe_notificationsettings'].reject { |_k, v| v.nil? }
  return if notify_prefs.empty?
  if node.os_less_than?('10.15')
    Chef::Log.warn(
      'cpe_notificationsettings requires 10.15 and higher.',
    )
    return
  else
    prefix = node['cpe_profiles']['prefix']
    organization = node['organization'] ? node['organization'] : 'Uber'
    # rubocop:enable Style/UnneededCondition
    notify_profile = {
      'PayloadIdentifier' => "#{prefix}.notificationsettings",
      'PayloadRemovalDisallowed' => true,
      'PayloadScope' => 'System',
      'PayloadType' => 'Configuration',
      'PayloadUUID' => '0894A148-12F6-44D7-B0AF-F82AE4330025',
      'PayloadOrganization' => organization,
      'PayloadVersion' => 1,
      'PayloadDisplayName' => 'Notification Center Settings',
      'PayloadContent' => [],
    }
    unless notify_prefs.empty?
      notify_profile['PayloadContent'].push(
        'PayloadType' => 'com.apple.notificationsettings',
        'PayloadVersion' => 1,
        'PayloadIdentifier' => "#{prefix}.notificationsettings",
        'PayloadUUID' => '034FE310-7629-452F-9EB8-5CA7390DD35A',
        'PayloadEnabled' => true,
        'PayloadDisplayName' => 'Notification Center Settings',
      )
      notify_prefs.each_key do |key|
        next if notify_prefs[key].nil?
        notify_profile['PayloadContent'][0][key] = notify_prefs[key]
      end
    end

    node.default['cpe_profiles']["#{prefix}.notificationsettings"] =
      notify_profile
  end
end
