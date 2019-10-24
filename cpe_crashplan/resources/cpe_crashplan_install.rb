#
# Cookbook:: cpe_crashplan
# Resources:: cpe_crashplan_install
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_crashplan_install
provides :cpe_crashplan_install, :os => 'darwin'
default_action :manage

action :manage do
  install if install? && !uninstall?
  uninstall if uninstall?
end
action_class do
  def install?
    node['cpe_crashplan']['install']
  end

  def uninstall?
    node['cpe_crashplan']['uninstall']
  end

  def cleanup_crashplan
    case node['platform_family']
    when 'mac_os_x'
      # spaces in script path, requires "''" in execute name.
      execute "'#{node['cpe_crashplan']['uninstall_script']}'" do
        only_if { ::File.exist?(node['cpe_crashplan']['uninstall_script']) }
      end

      directory 'cleanup crashplan dir' do
        path node['cpe_crashplan']['pkg']['base_path']
        recursive true
        user 'root'
        action :delete
      end
    end
  end

  def get_guid
    res = ''
    idfile = node['cpe_crashplan']['identity_file']
    if ::File.exist?(idfile)
      begin
        fetch = ::File.read(idfile)[/guid=(.*)/, 1]
        res = "guid=#{fetch}" unless fetch.nil?
      rescue EACCES, ENOENT => e
        Chef::Log.info("#{cookbook_name}: #{e} when retrieving guid.")
      end
    end
    return res
  end

  def upgrade_crashplan?
    cp = node['cpe_crashplan'].reject { |_k, v| v.nil? }

    ver = node.macos_application_version(
      '/Applications/CrashPlan.app/Contents/Info.plist',
      'CFBundleShortVersionString',
    )

    if node['cpe_crashplan']['prevent_downgrades']
      # When prevent_downgrades is true, ['pkg']['version'] must be less
      # than installed version in order to trigger install
      node.greater_than?(cp['pkg']['version'], ver)
    else
      # When prevent_downgrades is false, ['pkg']['version'] must not be equal
      # to installed version in order to trigger install
      node.not_eql?(cp['pkg']['version'], ver)
    end
  end

  def configure
    cp = node['cpe_crashplan'].reject { |_k, v| v.nil? }
    # lay down the deploy properties config file which tells CP how to
    # communicate with the CP server.
    template "#{cp['pkg']['base_path']}/deploy.properties" do
      source 'deploy.properties.erb'
      action :create
      owner root_owner
      group root_group
      mode  '0755'
      variables({
                  :url => cp['config']['url'],
                  :policy_token => cp['config']['policy_token'],
                  :ssl_whitelist => cp['config']['ssl_whitelist'],
                })
    end

    # process custom support files for crashplan server side scripts.
    # this is not a requirement in all builds.
    cp['custom_files'].each do |file, contents|
      file "#{cp['pkg']['base_path']}/#{file}" do
        content contents
        owner root_owner
        group root_group
        mode  '0755'
        only_if { cp['use_custom_files'] }
      end
    end
  end

  def install
    return unless node.macos?

    installed = node.macos_package_installed?(
      'com.crashplan.app.pkg',
      1,
    )

    upgrade_needed = upgrade_crashplan? if node.macos?
    return if installed && !upgrade_needed # Already installed and correct ver

    mac_os_x_install(upgrade_needed) if node.macos?
  end

  def mac_os_x_install(upgrade_needed)
    cp = node['cpe_crashplan'].reject { |_k, v| v.nil? }

    # Start upgrade only proceedures
    # save guid to var
    guid = cp['preserve_guid_on_upgrade'] ? get_guid : ''

    # run preinstall tasks on upgrades
    cleanup_crashplan if upgrade_needed

    directory "create #{cp['pkg']['base_path']} directory" do
      path  cp['pkg']['base_path']
      owner root_owner
      group root_group
      mode  '0755'
      action :create
    end

    # Reconstruct guid within identity file on preserve_guid true
    file cp['identity_file'] do
      content guid
      owner root_owner
      group root_group
      mode  '0600'
      action :create
      only_if { upgrade_needed }
      not_if { guid.empty? }
    end

    # run configuration tasks
    configure if node.macos?

    # Download and install CrashPlan
    cpe_remote_pkg 'crashplan' do
      app cp['pkg']['app_name']
      version cp['pkg']['version']
      checksum cp['pkg']['checksum']
    end
  end

  def uninstall
    cleanup_crashplan
  end
end
# rubocop:enable Metrics/BlockLength
