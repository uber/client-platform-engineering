cpe_workspaceone Cookbook
========================
Installs WorkspaceOne Intelligent Hub, manages its config and also enforces MDM profiles using the new `hubcli` tool available with console v1910.

This cookbook depends on the following cookbooks

* cpe_remote
* cpe_utils

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

* uber_helpers

Attributes
----------
* node['cpe_workspaceone']
* node['cpe_workspaceone']['cache_invalidation']
* node['cpe_workspaceone']['hubcli_path']
* node['cpe_workspaceone']['hubcli_timeout']
* node['cpe_workspaceone']['install']
* node['cpe_workspaceone']['manage']
* node['cpe_workspaceone']['manage_cli']
* node['cpe_workspaceone']['mdm_profiles']
* node['cpe_workspaceone']['mdm_profiles']['enforce']
* node['cpe_workspaceone']['mdm_profiles']['profiles']
* node['cpe_workspaceone']['mdm_profiles']['profiles']['device']
* node['cpe_workspaceone']['mdm_profiles']['profiles']['user']
* node['cpe_workspaceone']['mdm_profiles']['profiles']['force']
* node['cpe_workspaceone']['pkg']
* node['cpe_workspaceone']['pkg']['allow_downgrade']
* node['cpe_workspaceone']['pkg']['app_name']
* node['cpe_workspaceone']['pkg']['checksum']
* node['cpe_workspaceone']['pkg']['pkg_name']
* node['cpe_workspaceone']['pkg']['pkg_url']
* node['cpe_workspaceone']['pkg']['receipt']
* node['cpe_workspaceone']['pkg']['version']
* node['cpe_workspaceone']['pkg']['headers']
* node['cpe_workspaceone']['prefs']
* node['cpe_workspaceone']['uninstall']
* node['cpe_workspaceone']['use_cache']
* node['cpe_workspaceone']['cli_prefs']
* node['cpe_workspaceone']['cli_prefs']['checkin-interval']
* node['cpe_workspaceone']['cli_prefs']['menubar-icon']
* node['cpe_workspaceone']['cli_prefs']['sample-interval']
* node['cpe_workspaceone']['cli_prefs']['transmit-interval']

Usage
-----

# Profile and preferences
The profile will manage the `com.vmware.hub.agent` preference domain.

The profile's organization key defaults to `Uber` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload of all keys in `node['cpe_workspaceone]['prefs']` that are non-nil values.  The provided key `node['cpe_workspaceone']['HubAgentIconVisiblePreference']` are nil, so that no profile is installed by default.

You can add any arbitrary keys to `node['cpe_workspaceone']['prefs']` to have them added to your profile.  As long as the values are not nil and create a valid profile, this cookbook will install and manage them.

Due to the fact that `cpe_profiles` usually runs last or second to last in a typical run list, a `macos_userdefaults` call is made during the `manage` resource block. This is so if you chose to disable the menubar, it will be honored at the time of agent installation. This call cannot be made while the agent is running as it is unfortunately not honored by Workspace One at this time.

# CLI Config

Separate preferences are available through `hubcli config`. If node['cpe_workspaceone']['manage_cli'] is true, this cookbook will manage them.

```
'cli_prefs' => {
  'checkin-interval' => 60,
  'menubar-icon' => true,
  'sample-interval' => 60,
  'transmit-interval' => 60,
}
```

The defaults here are set in case of `nil`. See `hubcli config --help` for more information.

The cookbook intentionally does not manage 'server-url' or 'awcm-url'.

# Package
By default the package will not be installed. If you need to test a beta release of the agent, be aware that `allow_downgrade` value will not be honored if there is a space in the version number. As of v1910, the beta version string is '19.10 Beta' which causes the built in ruby gem `Gem::Version` to fail.

# HubCLI information and enforcing profiles
`hubcli` is a new tool as of v1910 agent, that allows an administrator to effectively manage and enforce MDM profiles locally at the device level. While there is a symbolic link created at the time of the agent install/upgrade at `/usr/local/bin/hubcli`, this cookbook defaults to the explicit path, located within the agent application.

`cpe_workspaceone` will enforce a list of profiles, based on the Name of the profile set within the console. Both Device and User level profiles are able to be scoped.

As of v1910, there is only an installation feature. If for some reason you need to remove profiles, you must use the Console API or the Console administration pages.

Please note that as of macOS Catalina, the key `PayloadRemovalDisallowed` is no longer honored at the MDM level if the value is set to `False`. This effectively means that **only** the mdmclient can remove MDM profiles, regardless if a user is an administrator on the device or not.

## HubCLI cache
By default, `cpe_workspaceone` one will create a cache of the json in the default chef cache folder.

By default, this cache will be invalidated in the following situations:
- Cache age is over 2 hours (7200) seconds. This value can be changed with the `node['cpe_workspaceone']['cache_invalidation']` object.
- Device is running a higher OS version than the cached json version.

If you do not want to use the cache, simply set `node['cpe_workspaceone']['use_cache']` to `false`.

Example
-----
# Enforce MDM profiles
node.default['cpe_workspaceone']['mdm_profiles']['enforce'] = true
# Device Profiles
node.default['cpe_workspaceone']['mdm_profiles']['profiles']['device'] = [
  'ExampleDeviceScopedProfileName',
]
# User Profiles
node.default['cpe_workspaceone']['mdm_profiles']['profiles']['user'] = [
  'ExampleUserScopedProfileName',
]
# Forced Profiles
Force profiles will always be requested for install from hubcli, even if already installed. This can be useful if the profile install has side effects you wish to [re]trigger, like adding an identity to the keychain.

node['cpe_workspaceone']['mdm_profiles']['profiles']['user_forced'] = [
  'ExampleForceInstalledUserProfileName'
]

node['cpe_workspaceone']['mdm_profiles']['profiles']['device_forced'] = [
  'ExampleForceInstalledDeviceProfileName'
]

# Manage the preferences of the hub
node.default['cpe_workspaceone']['manage'] = true
# Disable the menubar if you don't want people to know you've deployed the agent
node.default['cpe_workspaceone']['prefs'] = {
  'HubAgentIconVisiblePreference' => false,
}

# Install the agent
node.default['cpe_workspaceone']['install'] = true
# Installing a custom beta package
{
  'checksum' => '0d83adceaba5a6a9d6cba7d4acec89ded10de1aea80522d91585bc4d4c6317b9',
  'pkg_name' => 'workspace_one_intelligent_hub-19.10b2',
  'version' => '19.10 Beta',
}.each do |k, v|
  node.default['cpe_workspaceone']['pkg'][k] = v
end
