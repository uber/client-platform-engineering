#
# Cookbook:: cpe_ssh
# Resources:: cpe_ssh
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

resource_name :cpe_ssh
provides :cpe_ssh, :os => ['darwin', 'linux']

default_action :manage

action :manage do
  configure if node['cpe_ssh']['manage']
  cleanup unless node['cpe_ssh']['manage']
end

action_class do # rubocop:disable Metrics/BlockLength
  def configure
    # Get info about ssh config, rejecting unset values
    cpe_ssh_config = node['cpe_ssh']['config'].to_h.reject do |_k, v|
      v.nil? || v.empty?
    end
    ssh_config_set = true
    if cpe_ssh_config.empty? || cpe_ssh_config.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      ssh_config_set = false
    end

    cpe_known_hosts = node['cpe_ssh']['known_hosts'].compact

    # Read in /etc/ssh/ssh_config
    ssh_config = CPE::SSH.read_config

    # If there is a valid config
    if ssh_config_set
      # If the include directive does not exist, add it to the list to be included
      unless CPE::SSH.chef_managed_config?
        ssh_config += CPE::SSH.ssh_config_lines
      end

      update_ssh_config_hosts(ssh_config)

    # If there is no longer a config set, make sure to remove include, ssh config
    # hosts and delete the config on disk
    elsif !ssh_config_set
      remove_cpe_include(ssh_config)
      remove_ssh_config_hosts(ssh_config)
      # Make sure to delete the file if we no longer have any configs set
      file CPE::SSH.cpe_config_path do
        action :delete
      end
    end

    # Manage /etc/ssh/ssh_config
    # Note, we only look at lines which contain the desired directives
    file CPE::SSH.config_path do
      owner root_owner
      group node['root_group']
      mode '0644'
      content ssh_config.join
    end
    # Write out ssh_config_cpe
    template CPE::SSH.cpe_config_path do
      only_if { ssh_config_set }
      source 'ssh_config_cpe.erb'
      owner root_owner
      group node['root_group']
      mode '0644'
      variables(
        'config' => cpe_ssh_config,
      )
    end
    # Write out known_hosts_cpe, even if empty, so users know chef owns it
    template CPE::SSH.known_hosts_path do
      source 'known_hosts_cpe.erb'
      owner root_owner
      group node['root_group']
      mode '0644'
      variables(
        'config' => cpe_known_hosts,
      )
    end
  end

  def cleanup
    # If this is no longer managed, remove directives from ssh_config
    if CPE::SSH.chef_managed?
      ssh_config = CPE::SSH.read_config
      remove_cpe_include(ssh_config)
      file CPE::SSH.config_path do
        owner root_owner
        group node['root_group']
        mode '0644'
        content ssh_config.join
      end
    end
    # Also delete ssh_config_cpe and known_host_cpe files
    file CPE::SSH.cpe_config_path do
      action :delete
    end
    file CPE::SSH.known_hosts_path do
      action :delete
    end
  end

  def remove_cpe_include(ssh_config)
    tag_index = ssh_config.index("#{CPE::SSH::CHEF_MANAGED_TAG}\n")
    if tag_index && tag_index >= 0
      ssh_config.slice!(tag_index..tag_index + 1)
    end
  end

  def update_ssh_config_hosts(ssh_config)
    unless node['cpe_ssh']['config']['ssh_config_host'].nil?
      remove_ssh_config_hosts(ssh_config)
      ssh_config.append("#{CPE::SSH::BEGIN_HOST_TAG}\n")
      node['cpe_ssh']['config']['ssh_config_host'].each do |name, conf|
        ssh_config.append("Host #{name}\n")
        conf.each do |k, v|
          ssh_config.append("   #{k} #{v}\n")
        end
      end
      ssh_config.append("#{CPE::SSH::END_HOST_TAG}\n")
    end
  end

  def remove_ssh_config_hosts(ssh_config)
    begin_index = ssh_config.index("#{CPE::SSH::BEGIN_HOST_TAG}\n")
    end_index = ssh_config.index("#{CPE::SSH::END_HOST_TAG}\n")
    if begin_index && begin_index >= 0 && end_index && end_index >= 0 && end_index > begin_index
      ssh_config.slice!(begin_index..end_index)
    end
  end
end
