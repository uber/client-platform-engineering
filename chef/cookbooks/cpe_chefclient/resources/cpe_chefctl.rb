#
# Cookbook:: cpe_chefclient
# Resources:: cpe_chefclient
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

resource_name :cpe_chefclient
provides :cpe_chefclient, :os => ['darwin', 'linux', 'windows']

default_action :manage

action :manage do
  configure if configure? && !unmanage?
  unmanage if unmanage?
end

action_class do # rubocop:disable Metrics/BlockLength
  def configure?
    node['cpe_chefclient']['configure']
  end

  def unmanage?
    node['cpe_chefclient']['unmanage']
  end

  def configure
    configs = node['cpe_chefclient']['config'].to_hash
    configs_to_manage = []
    chef_path = node['cpe_chefclient']['path']
    chef_run_list = node['cpe_chefclient']['run_list'].to_hash
    configs.each do |conf_name, conf|
      chef =  conf.key?('chef') ? conf['chef'].compact : {}
      ohai = conf.key?('ohai') ? conf['ohai'].compact : {}
      ## This should work even if only one has contents
      next if chef.empty? && ohai.empty?

      config_path = ::File.join(
        chef_path,
        "#{conf_name}.rb",
      )
      # Lay down config for this config version
      template config_path do
        source 'client.rb.erb'
        variables(
          'chef' => chef,
          'ohai' => ohai,
        )
      end
      configs_to_manage << config_path
    end
    config_json = ::File.join(chef_path, '.cpe_chefclient.json')
    cleanup(configs_to_manage, config_json)
    update_json_file(configs_to_manage, config_json)
    # Lay down the run-list
    unless chef_run_list.nil? || chef_run_list.empty?
      run_list_json = ::File.join(chef_path, 'run-list.json')
      update_json_file(chef_run_list, run_list_json)
    end
  end

  def unmanage
    config_json = ::File.join(
      node['cpe_chefclient']['path'],
      '.cpe_chefclient.json',
    )
    configs_to_manage = [] # Unmanage, so remove all existing configs
    cleanup(configs_to_manage, config_json) if ::File.exist?(config_json)
    file config_json do
      path config_json # In case it is a symlink
      action :delete
    end
    run_list_json = ::File.join(
      node['cpe_chefclient']['path'],
      'run-list.json',
    )
    file run_list_json do
      path run_list_json # In case it is a symlink
      action :delete
    end
  end

  def cleanup(configs_to_manage, json_path)
    current_managed_configs = []

    # Parse the current json and see which files were installed last run
    if ::File.exists?(json_path)
      current_managed_configs = Chef::JSONCompat.parse(::File.read(json_path))
    else
      Chef::Log.warn('cpe_chefclient cannot find JSON or track/process files')
      return
    end

    # Loop through the managed files from last chef run
    current_managed_configs.each do |managed_config|
      # If file is not in our new list of items to manage, we need to delete it
      unless configs_to_manage.include?(managed_config)
        file managed_config do
          path managed_config # In case it is a symlink
          action :delete
        end
      end
    end
  end

  def update_json_file(configs_to_manage, json_path)
    # Update our json file (if needed) with the new contents of our items
    file json_path do
      mode '0644' unless windows?
      owner root_owner unless windows?
      group node['root_group'] unless windows?
      content Chef::JSONCompat.to_json_pretty(configs_to_manage)
    end
  end
end
