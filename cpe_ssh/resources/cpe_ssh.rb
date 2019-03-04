#
# Cookbook Name:: cpe_ssh
# Resources:: cpe_ssh
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_ssh
provides :cpe_ssh, :platform => ['mac_os_x', 'ubuntu']
default_action :manage

action :manage do
  configure if node['cpe_ssh']['manage']
  cleanup unless node['cpe_ssh']['manage']
end

action_class do
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

    cpe_known_hosts = node['cpe_ssh']['known_hosts'].reject { |_k, v| v.nil? }

    # Read in /etc/ssh/ssh_config
    ssh_config = CPE::SSH.read_config

    # If there is a valid config and the Include directive does not exist, add
    # it to the list to be included
    if ssh_config_set && !CPE::SSH.chef_managed_config?
      ssh_config << "\n#{CPE::SSH.ssh_config_line}"
    # If there is no longer a config set, make sure to remove include and
    # delete the config on disk
    elsif !ssh_config_set
      ssh_config.reject! { |line| line.include?(CPE::SSH.ssh_config_line) }
      # Make sure to delete the file if we no longer have any configs set
      file CPE::SSH.cpe_config_path do
        action :delete
      end
    end

    # Manage /etc/ssh/ssh_config
    # Note, we only look at lines which contain the desired directives
    file CPE::SSH.config_path do
      owner root_owner
      group root_group
      mode '0644'
      content ssh_config.join
    end
    # Write out ssh_config_cpe
    template CPE::SSH.cpe_config_path do
      only_if { ssh_config_set }
      source 'ssh_config_cpe.erb'
      owner root_owner
      group root_group
      mode '0644'
      variables(
        'config' => cpe_ssh_config,
      )
    end
    # Write out known_hosts_cpe, even if empty, so users know chef owns it
    template CPE::SSH.known_hosts_path do
      source 'known_hosts_cpe.erb'
      owner root_owner
      group root_group
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
      ssh_config.reject! { |line| line.include?('# Chef Managed') }
      file CPE::SSH.config_path do
        owner root_owner
        group root_group
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
end
