#
# Cookbook:: cpe_chefctl
# Resources:: cpe_chefctl
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_chefctl
provides :cpe_chefctl, :os => ['darwin', 'linux', 'windows']

default_action :manage

action :manage do
  configure if configure? && !remove?
  remove if remove?
end

action_class do
  def configure?
    node['cpe_chefctl']['configure']
  end

  def remove?
    node['cpe_chefctl']['remove']
  end

  def configure
    chefctl_path = CPE::Chefctl.path(
      node['cpe_chefctl']['config']['paths']['chefctl'],
    )
    cookbook_file chefctl_path do
      source 'chefctl.rb'
      user root_owner
      group node['root_group']
      mode '0755'
    end

    lock_dir = ::File.dirname(
      node['cpe_chefctl']['config']['chefctl']['lock_file'],
    )
    directory lock_dir do
      recursive true
    end
    # Only symlink chefctl on macOS and linux
    unless windows?
      chefctl_symlink = ::File.join(
        node['cpe_chefctl']['config']['chefctl']['symlink'],
        'chefctl',
      )
      link chefctl_symlink do
        to chefctl_path
      end
    end

    conf = node['cpe_chefctl']['config']['chefctl'].compact
    return if conf.empty? || conf.nil?

    # ToDo - Make this cross platform
    config_path = CPE::Chefctl.config(
      node['cpe_chefctl']['config']['paths']['chefctl_config'],
    )
    template config_path do
      source 'chefctl_config.rb.erb'
      variables(
        'config' => conf,
      )
    end
  end

  def remove
    chefctl_path = CPE::Chefctl.path(
      node['cpe_chefctl']['config']['paths']['chefctl_config'],
    )
    config_path = CPE::Chefctl.config(
      node['cpe_chefctl']['config']['paths']['chefctl'],
    )
    [
      config_path,
      chefctl_path,
    ].each do |chefctl_file|
      file chefctl_file do
        action :delete
      end
    end
  end
end
