# We will no longer be supporting/maintaining this cookbook; use at your own discretion

cpe_crashplan Cookbook
========================
Installs and manages components of crashplan
see: https://support.code42.com/Administrator/Cloud/Planning_and_installing/Manage_app_installations_in_your_Code42_environment/Deployment_script_and_command_reference for more information on custom_files.
see https://support.code42.com/CrashPlan/6/Get_started/Uninstall_the_Code42_app for more information on uninstalling the package.
Requirements
------------

This cookbook depends on the following cookbooks

* cpe_utils
* cpe_remote

Attributes
----------
* node['cpe_crashplan']
* node['cpe_crashplan']['install']
* node['cpe_crashplan']['uninstall']
* node['cpe_crashplan']['prevent_downgrades']
* node['cpe_crashplan']['preserve_guid_on_upgrade']
* node['cpe_crashplan']['use_custom_files']
* node['cpe_crashplan']['uninstall_script']
* node['cpe_crashplan']['identity_file']
* node['cpe_crashplan']['pkg']['base_path']
* node['cpe_crashplan']['pkg']['app_name']
* node['cpe_crashplan']['pkg']['mac_os_x_pkg_receipt']
* node['cpe_crashplan']['pkg']['version']
* node['cpe_crashplan']['pkg']['checksum']
* node['cpe_crashplan']['config']['url']
* node['cpe_crashplan']['config']['policy_token']
* node['cpe_crashplan']['config']['ssl_whitelist']
* node['cpe_crashplan']['custom_files']

Notes
-----

Usage
-----
By default, this cookbook will not install crashplan or it's configuration

include_recipe 'cpe_crashplan'
