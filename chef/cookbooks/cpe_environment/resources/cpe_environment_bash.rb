#
# Cookbook:: cpe_environment
# Resource:: cpe_environment_bash
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_environment_bash
provides :cpe_environment_bash, :os => ['darwin', 'linux']

default_action :manage

action :manage do
  configure if node['cpe_environment']['manage']
  cleanup unless node['cpe_environment']['manage']
end

action_class do # rubocop:disable Metrics/BlockLength
  def bash_config_file
    if macos?
      '/etc/profile'
    else
      '/etc/bash.bashrc'
    end
  end

  def cpe_profiled_file
    '/etc/profile_cpe'
  end

  def cpe_config_file
    '/etc/profile.d/cpe.sh'
  end

  def configure
    # Catalina and higher don't even read /etc/profile, so lets skip this
    return if macos? && node.os_at_least?('10.15')

    # Check config to make sure its not empty
    cpe_bash_config = node['cpe_environment']['config'].to_h.reject do |_k, v|
      v.nil? || v.empty?
    end

    bash_config_set = true

    # Read in /etc/profile on macOS or /etc/bash.bashrc on linux
    bash_config = CPE::Environment.read_config(bash_config_file)

    if cpe_bash_config.nil? || cpe_bash_config.empty?
      Chef::Log.warn('config is not populated, skipping configuration')
      bash_config_set = false
    end

    # On macOS and ubuntu, it doesn't utilize profile.d by default,
    # so lets set that up
    # Place our stub /etc/profile_cpe to include anything inside of profile.d
    cookbook_file cpe_profiled_file do
      source 'profile_cpe'
      owner root_owner
      group node['root_group']
      mode '0644'
    end

    # If there is a valid config and the cpe bash source line does not exist, add it
    if bash_config_set && !CPE::Environment.profile_chef_managed?(bash_config_file, cpe_profiled_file)
      bash_config += CPE::Environment.bash_config_lines(cpe_profiled_file)
    # If there is no longer a config set, make sure to remove include and
    # delete the config on disk
    elsif !bash_config_set
      remove_bash_source(bash_config)
      # Make sure to delete the file if we no longer have any configs set
      file cpe_config_file do
        action :delete
      end
    end

    # Manage our include lines in /etc/profile
    file bash_config_file do
      owner root_owner
      group node['root_group']
      mode '0644'
      content bash_config.join
    end

    # /etc/profile.d doesn't exist on macOS by default
    directory '/etc/profile.d' do
      owner root_owner
      group node['root_group']
    end

    # Place our actual config into /etc/profile.d/cpe.sh
    template cpe_config_file do
      only_if { bash_config_set }
      source 'bash_cpe.erb'
      owner root_owner
      group node['root_group']
      mode '0644'
      variables(
        'config' => cpe_bash_config,
      )
    end
  end

  def cleanup
    # If this is no longer managed, remove configs
    if CPE::Environment.chef_managed?(bash_config_file)
      bash_config = CPE::Environment.read_config(bash_config_file)
      remove_bash_source(bash_config)
      file bash_config_file do
        owner root_owner
        group node['root_group']
        mode '0644'
        content bash_config.join
      end
    end
    # Delete the macOS profile.d include file
    file cpe_profiled_file do
      action :delete
    end
    # Delete the actual cpe.sh from profile.d
    file cpe_config_file do
      action :delete
    end
  end

  def remove_bash_source(bash_config)
    tag_index = bash_config.index(CPE::Environment::CHEF_MANAGED_TAG)
    if tag_index && tag_index >= 0
      bash_config.slice!(tag_index..tag_index + 1)
    end
  end
end
