#
# Cookbook Name:: cpe_sal
# Resources:: cpe_sal
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_sal
provides :cpe_sal, :os => 'darwin'
default_action :manage

action :manage do
  install
  configure
  manage_plugins
  cleanup
end

action_class do # rubocop:disable Metrics/BlockLength
  def install
    return unless node['cpe_sal']['install']

    # Get info about the sal_scripts pkg, rejecting unset values
    pkg_info = node['cpe_sal']['scripts_pkg'].reject { |_k, v| v.nil? }
    if pkg_info.empty? || pkg_info.nil?
      Chef::Log.warn('scripts_pkg is not populated, skipping pkg install')
      return
    end

    # Install sal_scripts.pkg
    cpe_remote_pkg pkg_info['name'] do
      pkg_url pkg_info['pkg_url'] if pkg_info['pkg_url']
      pkg_name pkg_info['pkg_name'] if pkg_info['pkg_name']
      version pkg_info['version']
      checksum pkg_info['checksum']
      receipt pkg_info['receipt']
    end
  end

  def configure
    return unless node['cpe_sal']['configure']

    # Get info about sal config, rejecting unset values
    sal_prefs = node['cpe_sal']['config'].reject { |_k, v| v.nil? }
    if sal_prefs.empty? || sal_prefs.nil?
      Chef::Log.warn('config is not populated, skipping configuration')
      return
    end

    # Build configuration profile and pass it to cpe_profiles
    prefix = node['cpe_profiles']['prefix']
    organization = node['organization'] ? node['organization'] : 'Uber' # rubocop:disable  Style/UnneededCondition, Metrics/LineLength

    sal_profile = {
      'PayloadIdentifier' => "#{prefix}.sal",
      'PayloadRemovalDisallowed' => true,
      'PayloadScope' => 'System',
      'PayloadType' => 'Configuration',
      'PayloadUUID' => '1c03dd17-d2d7-4a68-be40-f41bea3642a9',
      'PayloadOrganization' => organization,
      'PayloadVersion' => 1,
      'PayloadDisplayName' => 'Sal',
      'PayloadContent' => [],
    }
    sal_profile['PayloadContent'].push(
      'PayloadType' => 'com.github.salopensource.sal',
      'PayloadVersion' => 1,
      'PayloadIdentifier' => "#{prefix}.sal",
      'PayloadUUID' => 'e33adee2-4a19-4e69-a330-461920ec8279',
      'PayloadEnabled' => true,
      'PayloadDisplayName' => 'Sal',
    )
    sal_prefs.each do |k, v|
      sal_profile['PayloadContent'][0][k] = v
    end
    node.default['cpe_profiles']["#{prefix}.sal"] = sal_profile

    # Make sure the launchds are always loaded if present
    CPE::Sal.launchds.each do |d|
      launchd d do
        only_if { ::File.exist?("/Library/LaunchDaemons/#{d}.plist") }
        action :enable
      end
    end
  end

  def manage_plugins
    return unless node['cpe_sal']['manage_plugins']

    # Get plugins dir from cpe_sal library
    plugins_dir = CPE::Sal.plugins_dir
    plugins = node['cpe_sal']['plugins'].reject { |_k, v| v.nil? }
    if plugins.empty? && plugins.empty?
      Chef::Log.warn('plugins is not populated, skipping plugins install')
      return
    end

    plugins.each do |name, script|
      directory "#{plugins_dir}/#{name}_chef" do
        owner 'root'
        group 'wheel'
        mode '0755'
      end

      cookbook_file "#{plugins_dir}/#{name}_chef/#{script}" do
        source script
        owner 'root'
        group 'wheel'
        mode '0750'
      end
    end
  end

  def cleanup
    # Get plugins dir and currently installed plugins list from cpe_sal library
    plugins_dir = CPE::Sal.plugins_dir
    if ::File.exist?(plugins_dir)
      existing_plugins = CPE::Sal.existing_plugins
      plugins = node['cpe_sal']['plugins'].reject { |_k, v| v.nil? }
      # If plugin directory exists on disk, but isn't managed, remove it.
      existing_plugins.each do |plugin|
        existing_plugin = plugin.split('_')[0]
        unless plugins.key?(existing_plugin)
          directory "#{plugins_dir}/#{existing_plugin}_chef" do
            recursive true
            action :delete
          end
        end
      end
    end

    unless node['cpe_sal']['configure']
      CPE::Sal.launchds.each do |d|
        launchd d do
          only_if { ::File.exist?("/Library/LaunchDaemons/#{d}.plist") }
          action :disable
        end
      end
    end
  end
end
