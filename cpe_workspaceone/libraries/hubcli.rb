#
# Cookbook Name:: cpe_workspaceone
# Library:: hubcli
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

class Chef
  class Node
    # Only the top level device_attributes object is memoized as we won't actually call
    # anything if it been called previously in the chef run.
    def ws1_device_attributes
      @ws1_device_attributes ||=
        begin
          unless node.macos?
            Chef::Log.warn('node.ws1_device_attributes called on non-macOS!')
            return {}
          end

          # Bail if device is not enrolled into mdm
          return {} unless node.profile_installed?('ProfileDisplayName', 'Device Manager')

          hubcli_path = node['cpe_workspaceone']['hubcli_path']
          # Bail if hubcli doesn't exist
          return {} unless ws1_hubcli_exists

          # If for some reason an admin doesn't want to use the cache, always return the json from WS1
          ws1_use_cache = node['cpe_workspaceone']['use_cache']
          return _get_available_ws1_profiles_list unless ws1_use_cache

          # Setup cache file
          ws1_cache_file_path = ::File.join(Chef::Config[:file_cache_path], 'cpe_workspaceone-device_attributes.json')
          ws1_cache_exists = ::File.exist?(ws1_cache_file_path)
          ws1_cache_old = ws1_json_age_over_invalidation?(ws1_cache_file_path)

          # Cache exists and is fresh - utilize cache
          if ws1_cache_exists && !ws1_cache_old
            parsed_ws1_json = node.parse_json(ws1_cache_file_path)
            # Check the OS version of the json contents vs current version. If the current OS is greater than the
            # last checked OS version (Example, upgrading from 10.14 to 10.15 in between two hour chef cache), reject
            # the current cache and check again, so we can look for newly available profiles.
            if node.greater_than?(node['platform_version'], parsed_ws1_json['os_version'])
              ws1_device_attributes = _get_available_ws1_profiles_list
            else
              return parsed_ws1_json
            end
          # Cache either doesn't exist or isn't fresh
          else
            ws1_device_attributes = _get_available_ws1_profiles_list
          end

          # Only write the attributes if they come back in a good, clean state
          unless ws1_device_attributes.empty?
            node.write_contents_to_file(ws1_cache_file_path, Chef::JSONCompat.to_json_pretty(ws1_device_attributes))
          end

          ws1_device_attributes
        rescue Exception => e # rubocop:disable Lint/RescueException
          Chef::Log.warn("Failed to get workspace one device attributes with error #{e}")
          {}
        end
    end

    def ws1_hubcli_exists
      @ws1_hubcli_exists ||=
        begin
          !node['cpe_workspaceone']['hubcli_path'].nil? && ::File.exists?(node['cpe_workspaceone']['hubcli_path'])
        end
    end

    def hubcli_path
      return 'hubcli' unless @ws1_hubcli_exists

      return node['cpe_workspaceone']['hubcli_path'].gsub(/ /, '\ ')
    end

    def hubcli_execute(cmd, execute=true)
      cmd = "#{hubcli_path} #{cmd.strip}"
      if execute
        cmd = shell_out(cmd)
      end
      cmd
    end

    def _get_available_ws1_profiles_list
      attributes = {}
      if node.macos?
        # spaces in path, so we need to convert them with gsub
        cmd = hubcli_execute(
          "profiles --list --json",
        )
      end
      if cmd.exitstatus.zero?
        if node.macos?
          attributes = Chef::JSONCompat.parse(cmd.stdout.to_s)
        end
      else
        return attributes
      end

      # Bail if the attributes are empty
      return {} if attributes.empty?

      # add the OS version so we can do intelligent actions
      if node.macos?
        attributes['os_version'] = node['platform_version']
      end

      attributes
    end

    def ws1_json_age_over_invalidation?(path_of_file)
      @ws1_json_age_over_invalidation ||=
        begin
          age_length = false
          if ::File.exist?(path_of_file)
            diff_time = (Time.now - File.mtime(path_of_file)).to_i
            age_length = diff_time > node['cpe_workspaceone']['cache_invalidation']
          end
          age_length
        end
    end
  end
end
