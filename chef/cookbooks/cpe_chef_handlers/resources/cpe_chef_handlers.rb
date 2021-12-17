#
# Cookbook:: cpe_chef_handlers
# Resources:: cpe_chef_handlers
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

resource_name :cpe_chef_handlers
provides :cpe_chef_handlers, :os => ['darwin', 'linux', 'windows']

default_action :manage

action :manage do
  configure if configure? && !remove?
  remove if remove?
end

action_class do
  def configure?
    node['cpe_chef_handlers']['configure']
  end

  def remove?
    node['cpe_chef_handlers']['remove']
  end

  def configure
    conf = node['cpe_chef_handlers']['configs'].to_h.compact
    return if conf.empty? && conf.empty?

    config_dir = node['cpe_chef_handlers']['paths']['configdir']
    directory config_dir do
      action :create
    end
    # Assemble path to the client_handlers.rb config
    handler_config = CPE::ChefHandlers.config(
      config_dir,
    )
    template handler_config do
      source 'client_handlers.rb.erb'
      variables(
        'handlerdir' => node['cpe_chef_handlers']['paths']['handlerdir'],
        'configs' => conf,
      )
    end
  end

  def remove
    handler_config = CPE::ChefHandlers.config(
      node['cpe_chefctl']['config']['paths']['configdir'],
    )
    file handler_config do
      action :delete
    end
  end
end
