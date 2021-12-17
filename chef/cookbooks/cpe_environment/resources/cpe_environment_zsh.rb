#
# Cookbook:: cpe_environment
# Resource:: cpe_environment_zsh
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_environment_zsh
provides :cpe_environment_zsh, :os => ['darwin', 'linux']

default_action :manage

action :manage do
  configure if node['cpe_environment']['manage']
  cleanup unless node['cpe_environment']['manage']
end

action_class do
  def zsh_config_file
    if macos?
      '/etc/zshenv'
    else
      '/etc/zsh/zshenv'
    end
  end

  def cpe_zsh_dir
    '/etc/zsh'
  end

  def cpe_config_file
    "#{cpe_zsh_dir}/cpe"
  end

  def configure
    ## Check config to make sure its not empty
    cpe_zsh_config = node['cpe_environment']['config'].to_h.reject do |_k, v|
      v.nil? || v.empty?
    end
    zsh_config_set = true

    # Read in /etc/zshenv
    zsh_config = CPE::Environment.read_config(zsh_config_file)

    if cpe_zsh_config.nil? || cpe_zsh_config.empty?
      Chef::Log.warn('config is not populated, skipping configuration')
      zsh_config_set = false
    end

    # If there is a valid config and the cpe zsh source line does not exist, add
    # it to the list to be included
    if zsh_config_set && !CPE::Environment.zsh_chef_managed?(zsh_config_file, cpe_config_file)
      zsh_config += CPE::Environment.zsh_config_lines(cpe_config_file)
    # If there is no longer a config set, make sure to remove include and
    # delete the config on disk
    elsif !zsh_config_set
      remove_zsh_source(zsh_config)
      # Make sure to delete the file if we no longer have any configs set
      file cpe_config_file do
        action :delete
      end
    end

    # Manage our include lines in /etc/zshenv
    file zsh_config_file do
      owner root_owner
      group node['root_group']
      mode '0644'
      content zsh_config.join
    end

    directory cpe_zsh_dir do
      owner root_owner
      group node['root_group']
    end

    template cpe_config_file do
      only_if { zsh_config_set }
      source 'zsh_cpe.erb'
      owner root_owner
      group node['root_group']
      mode '0644'
      variables(
        'config' => cpe_zsh_config,
      )
    end
  end

  def cleanup
    # If this is no longer managed, remove directives from ssh_config
    if CPE::Environment.chef_managed?(zsh_config_file)
      zsh_config = CPE::Environment.read_config(zsh_config_file)
      remove_zsh_source(zsh_config)
      file zsh_config_file do
        owner root_owner
        group node['root_group']
        mode '0644'
        content zsh_config.join
      end
    end
    # Also delete ssh_config_cpe and known_host_cpe files
    file cpe_config_file do
      action :delete
    end
  end

  def remove_zsh_source(zsh_config)
    tag_index = zsh_config.index(CPE::Environment::CHEF_MANAGED_TAG)
    if tag_index && tag_index >= 0
      zsh_config.slice!(tag_index..tag_index + 1)
    end
  end
end
