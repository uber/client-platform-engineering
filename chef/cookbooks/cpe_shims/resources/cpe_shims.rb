#
# Cookbook:: cpe_shims
# Resources:: cpe_shims
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true if node['chef_packages']['chef']['version'] >= '15.3.0'

resource_name :cpe_shims
provides :cpe_shims, :os => ['darwin', 'linux']

default_action :manage

action :manage do
  manage if manage?
  unmanage if !manage? && unmanage?
end

action_class do
  def manage?
    node['cpe_shims']['manage']
  end

  def unmanage?
    node['cpe_shims']['unmanage']
  end

  def shim_unix_os?
    debian? || macos?
  end

  def cleanup(items_to_manage, json_path)
    current_managed_files = []

    # Parse the current json and see which files were installed last run
    if ::File.exists?(json_path)
      current_managed_files = Chef::JSONCompat.parse(::File.read(json_path))
    else
      Chef::Log.warn('cpe_shims cannot find JSON or track/process files')
      return
    end

    # Loop through the managed files from last chef run
    current_managed_files.each do |managed_file|
      # If file is not in our new list of items to manage, we need to delete it
      unless items_to_manage.include?(managed_file)
        file managed_file do
          path managed_file # Here because Chef 14 erronously detected shim as
          # a symbolic link
          action :delete
        end
      end
    end
  end

  def update_json_file(items_to_manage, json_path)
    # Update our json file (if needed) with the new contents of our items
    file json_path do
      mode '0644'
      owner root_owner
      group node['root_group']
      action :create
      content Chef::JSONCompat.to_json_pretty(items_to_manage)
    end
  end

  def manage
    return unless node['cpe_shims']['manage']

    shims = node['cpe_shims']['shims'].to_hash
    return if shims.empty? || shims.nil?

    linux_manage(shims) if shim_unix_os?
    windows_manage if windows?

    items_to_manage = []
    # Process all of the paths for the shims
    shims.values.each do |shim|
      items_to_manage.push(shim['path'])
    end

    # Hardcoded json path for shims
    json_path = ::File.join(Chef::Config[:file_cache_path], 'cpe_shims.json')

    cleanup(items_to_manage, json_path) if shim_unix_os?
    update_json_file(items_to_manage, json_path) if shim_unix_os?
  end

  def linux_manage(shims)
    shims.to_hash.values.each do |shim|
      template shim['path'] do
        action :create
        group node['root_group']
        mode '0755'
        owner root_owner
        source 'bash.erb'
        variables({
                    :shebang => shim['shebang'],
                    :content => shim['content'],
                  })
      end
    end
  end

  def windows_manage
    # TODO: need to write
    return
  end

  def unmanage
    return unless node['cpe_shims']['unmanage']

    items_to_manage = []

    # Hardcoded json path for shims
    json_path = ::File.join(Chef::Config[:file_cache_path], 'cpe_shims.json')

    cleanup(items_to_manage, json_path) if shim_unix_os?
    update_json_file(items_to_manage, json_path) if shim_unix_os?
  end
end
