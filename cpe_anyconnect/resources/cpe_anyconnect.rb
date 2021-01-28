#
# Cookbook Name:: cpe_anyconnect
# Resources:: cpe_anyconnect
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2021-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

resource_name :cpe_anyconnect
provides :cpe_anyconnect, :os => 'darwin'

default_action :manage

action :manage do
  manage if manage?
  install if install?
  uninstall if !install? && uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    node['cpe_anyconnect']['install']
  end

  def manage?
    node['cpe_anyconnect']['manage']
  end

  def uninstall?
    node['cpe_anyconnect']['uninstall']
  end

  def install
    debian_install if node.debian_family?
    macos_install if node.macos?
    windows_install if node.windows?
  end

  def debian_install
    # TODO: need to write
    return
  end

  def macos_install
    # Create package cache directories
    cache_path = node['cpe_anyconnect']['pkg']['cache_path']
    anyconnect_root_cache_path = ::File.join(cache_path, 'cisco_anyconnect')

    # Create cache path
    directory cache_path do
      group root_group
      owner root_owner
      mode '0755'
    end

    # Sync the entire anyconnect folder to handle any files an admin would need
    remote_directory anyconnect_root_cache_path do
      group root_group
      owner root_owner
      mode '0755'
      source 'anyconnect'
    end

    # package properties
    pkg_name = node['cpe_anyconnect']['pkg']['app_name']
    pkg_version = node['cpe_anyconnect']['pkg']['version']
    pkg_full_name = "#{pkg_name}-#{pkg_version}.pkg"
    pkg_path = ::File.join(anyconnect_root_cache_path, "#{pkg_name}.pkg")

    # cpe_remote_pkg doesn't support ChoiceChanges.xml which is needed to not install specific parts of this package
    # Download the anyconnect pkg
    cpe_remote_file pkg_name do
      file_name pkg_full_name
      checksum node['cpe_anyconnect']['pkg']['checksum']
      path pkg_path
    end

    # Install the pacakge with the ChoiceChangesXML
    cc_xml_path = ::File.join(anyconnect_root_cache_path, 'pkg', 'ChoiceChanges.xml')
    allow_downgrade = node['cpe_anyconnect']['pkg']['allow_downgrade']
    if allow_downgrade
      Chef::Log.warn('cpe_anyconnect - AnyConnect package has logic to fail if attempting to downgrade - you must '\
        'uninstall the application first!')
      Chef::Log.warn('cpe_anyconnect - forcing downgrade to false')
      allow_downgrade = False
    end
    execute "/usr/sbin/installer -applyChoiceChangesXML #{cc_xml_path} -pkg #{pkg_path} -target /" do
      # functionally equivalent to allow_downgrade false on cpe_remote_pkg
      unless allow_downgrade
        not_if { node.min_package_installed?(node['cpe_anyconnect']['pkg']['receipt'], pkg_version) }
      end
      notifies :create, 'file[trigger_gui]', :immediately
    end

    # We only want the UI to trigger upon the first install and upgrades.
    # In testing, their own postinstall script logic is very unreliable.
    # Touch the gui_keepalive path and then restart the agent will trigger the UI
    gui_la_label = node['cpe_anyconnect']['la_gui_identifier']
    file 'trigger_gui' do
      action :nothing
      only_if { ::File.exist?("/Library/LaunchAgents/#{gui_la_label}.plist") }
      path '/opt/cisco/anyconnect/gui_keepalive'
      notifies :restart, "launchd[#{gui_la_label}]", :immediately
    end

    launchd gui_la_label do
      type 'agent'
      action :nothing
    end
  end

  def windows_install
    # TODO: need to write
    return
  end

  def manage
    debian_manage if node.debian_family?
    macos_manage if node.macos?
    windows_manage if node.windows?
  end

  def debian_manage
    # TODO: need to write
    return
  end

  def macos_manage
    # If the Anyconnect App goes missing, either by accident or abuse, trigger re-install
    ac_receipt = node['cpe_anyconnect']['pkg']['receipt']
    unless ::Dir.exist?(node['cpe_anyconnect']['app_path'])
      execute "/usr/sbin/pkgutil --forget #{ac_receipt}" do
        not_if { shell_out("/usr/sbin/pkgutil --pkg-info #{ac_receipt}").error? }
      end
    end
  end

  def windows_manage
    # TODO: need to write
    return
  end

  def uninstall
    debian_uninstall if node.debian_family?
    macos_uninstall if node.macos?
    windows_uninstall if node.windows?
  end

  def debian_uninstall
    # TODO: need to write
    return
  end

  def macos_uninstall
    # TODO: need to write
    return
  end

  def windows_uninstall
    # TODO: need to write
    return
  end
end
