#
# Cookbook:: cpe_chefctl
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

default_conf = value_for_platform_family(
  'debian' => {
    'basedir' => '/etc',
    'chefdir' => '/etc/chef',
    'chefctl_lock_path' => '/var/lock/subsys',
    'chefctl_symlink_path' => '/usr/bin',
  },
  'mac_os_x' => {
    'basedir' => '/etc',
    'chefdir' => '/etc/chef',
    'chefctl_lock_path' => '/var/run',
    'chefctl_symlink_path' => '/usr/local/bin',
  },
  'windows' => {
    'basedir' => 'C:\chef',
    'chefdir' => 'C:\chef',
    'chefctl_lock_path' => 'C:\chef\cache',
    'chefctl_symlink_path' => nil,
  },
)

if macos?
  path = [
    '/usr/sbin', '/usr/bin', '/sbin', '/bin', '/usr/libexec', '/usr/local/bin'
  ]
elsif linux?
  path = ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
else
  path = nil
end

default['cpe_chefctl'] = {
  'configure' => false,
  'remove' => false,
  'config' => {
    'paths' => {
      'chefctl' => default_conf['chefdir'],
      'chefctl_config' => default_conf['basedir'],
    },
    'chefctl' => {
      'lock_file' => ::File.join(
        default_conf['chefctl_lock_path'],
        'chefctl',
      ),
      'path' => path,
      'symlink' => default_conf['chefctl_symlink_path'],
    },
  },
}
