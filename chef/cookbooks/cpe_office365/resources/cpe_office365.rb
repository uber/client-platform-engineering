#
# Cookbook:: cpe_office365
# Resources:: cpe_office365
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2021-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_office365
provides :cpe_office365, :os => ['windows']

default_action :manage

action :manage do
  install if install?
  uninstall if !install? && uninstall?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    node['cpe_office365']['install']
  end

  def uninstall?
    node['cpe_office365']['uninstall']
  end

  def configure_install
    template conf_path do
      source "#{conf_name}.erb"
      variables(
        :excluded_apps => office_365_excluded_apps,
        :migrate_arch => office_365_config_hash['migrate_arch'],
        :channel => office_365_config_hash['channel'],
        :office_client_edition => office_365_config_hash['office_client_edition'],
        :product_id => office_365_config_hash['product_id'],
        :shared_computer_licensing => office_365_config_hash['shared_computer_licensing'],
        :scl_cache_override => office_365_config_hash['scl_cache_override'],
        :auto_activate => office_365_config_hash['auto_activate'],
        :force_app_shutdown => office_365_config_hash['force_app_shutdown'],
        :device_based_licensing => office_365_config_hash['device_based_licensing'],
        :updates_enabled => office_365_config_hash['updates_enabled'],
        :company => office_365_config_hash['company'],
        :display_level => office_365_config_hash['display_level'],
        :accept_eula => office_365_config_hash['accept_eula'],
        :remove_msi => office_365_config_hash['remove_msi'],
        :match_os => office_365_config_hash['match_os'],
        :match_previous_msi => office_365_config_hash['match_previous_msi'],
        :exclude => office_365_config_hash['exclude'],
        :ignored_products => office_365_config_hash['ignored_products'],
      )
    end
  end

  def configure_uninstall
    template conf_path do
      source "#{conf_name}.erb"
      variables(
        :display_level => office_365_config_hash['display_level'],
        :accept_eula => office_365_config_hash['accept_eula'],
        :remove_all => office_365_config_hash['remove_all'],
        :remove_msi => office_365_config_hash['remove_msi'],
        :force_app_shutdown => office_365_config_hash['force_app_shutdown'],
      )
      only_if { office_365_pkg_installed? }
    end
  end

  def install
    configure_install
    # Download Office Executable
    cpe_remote_file bin_name do
      file_name exe_name
      checksum office_365_bin['checksum']
      path exe_path
    end
    # Create Scheduled task
    ps_cmd = "#{exe_path} /configure #{conf_path}"
    windows_task office_365_config_hash['conf_name'] do
      command ps_cmd
      frequency :none
      run_level :highest
    end
    # Run Scheduled Task
    windows_task office_365_config_hash['conf_name'] do
      action :run
      execution_time_limit 1800
      not_if { office_365_requested_apps_installed? }
      only_if { office_365_config_exist? }
    end
  end

  def uninstall
    configure_uninstall
    # Download Office Executable
    cpe_remote_file bin_name do
      file_name exe_name
      checksum office_365_bin['checksum']
      only_if { office_365_pkg_installed? }
      path exe_path
    end
    # Uninstall the package per the specified config file
    execute bin_name do
      command "#{exe_path} /configure #{conf_path}"
      notifies :delete, "file[#{conf_path}]", :delayed
      notifies :delete, "file[#{exe_path}]", :delayed
      timeout 600
      only_if { office_365_pkg_installed? }
      only_if { office_365_config_exist? }
    end
    # Cleanup Installation
    windows_task office_365_config_hash['conf_name'] do
      action :delete
    end

    file conf_path do
      action :nothing
    end

    file exe_path do
      action :nothing
    end
  end

  def office_365_requested_apps
    office_365_catalog_hash.select { |_k, v| v == true }.keys
  end

  def office_365_excluded_apps
    office_365_catalog_hash.select { |_k, v| v == false }.keys
  end

  def office_365_pkg_installed?
    node['packages'].keys.any? { |k| k.include?('Microsoft 365 Apps for enterprise') }
  end

  def office_365_app_installed?(app)
    # Unlike every other application, teams is an IM provider and lives under a seperate registry location
    regkey = 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Office\\ClickToRun\\REGISTRY\\MACHINE\\Software\\'
    app.include?('teams') ? key = regkey + 'IM Providers\\Teams' : key = regkey + "Classes\\#{app}.Application"
    registry_key_exists?(key, :x86_64)
  end

  def office_365_requested_apps_installed?
    office_365_requested_apps.all? { |app| office_365_app_installed?(app) }
  end

  def office_365_config_exist?
    ::File.exist?(conf_path)
  end

  def office_365_bin
    node['cpe_office365']['bin'].to_h.reject { |_k, v| v.nil? }
  end

  def office_365_config_hash
    node['cpe_office365']['config'].to_h.reject { |_k, v| v.nil? }
  end

  def office_365_catalog_hash
    node['cpe_office365']['catalog'].to_h.reject { |_k, v| v.nil? }
  end

  def bin_name
    office_365_bin['bin_name']
  end

  def exe_name
    "office_365-#{office_365_bin['version']}.exe"
  end

  def conf_name
    "#{office_365_config_hash['conf_name']}.xml"
  end

  def exe_path
    ::File.join(cache_path, exe_name)
  end

  def conf_path
    ::File.join(cache_path, conf_name)
  end

  def cache_path
    Chef::Config[:file_cache_path]
  end
end
