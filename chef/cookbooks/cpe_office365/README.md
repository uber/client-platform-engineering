cpe_office365 Cookbook
========================
Installs office365, and manages the config and services.

This cookbook depends on the following cookbooks

* cpe_remote

This cookbook is offered by Uber in the [IT-CPE](https://github.com/uber/IT-CPE) repository.

Attributes
----------
* node['cpe_office365']
* node['cpe_office365']['install']
* node['cpe_office365']['uninstall']
* node['cpe_office365']['catalog']
* node['cpe_office365']['config']
* node['cpe_office365']['bin']

Notes
-----
For details on configuration options, see the official microsoft documentation: https://docs.microsoft.com/en-us/deployoffice/office-deployment-tool-configuration-options

Usage
-----
Before using this cookbook to install Office365, you will need to determine how you will scope the

By default, this cookbook will not set any configuration options, the office 365
installer will fail to install office if no configuration is specified.

A config for installing O365 Pro Plus Retail might look like this:

The below is an example of our Config Options.
In This example we validate Active Directory Group membership
```ruby
if node.person_in_group?('office365-group')
node.default['cpe_office365']['install'] = true
  { # Set Custom configuration settings
    'conf_name' => 'office_365',
    'migrate_arch' => true,
    'channel' => 'Current',
    'office_client_edition' => 64,
    'product_id' => 'O365ProPlusRetail',
    'shared_computer_licensing' => 0,
    'scl_cache_override' => 0,
    'auto_activate' => 0,
    'force_app_shutdown' => true,
    'device_based_licensing' => 0,
    'updates_enabled' => true,
    'company' => 'UBER',
    'display_level' => 'None',
    'accept_eula' => true,
    'remove_msi' => true,
    'match_os' => true,
    'match_previous_msi' => true,
    'exclude' => true,
  }.each do |k, v|
    node.default['cpe_office365']['config'][k] = v
  end
```
To determine which Applications are installed you will need to update the Catalog Hash values
```ruby
  'catalog' => {
    'access' => false,
    'bing' => false,
    'excel' => false,
    'groove' => false,
    'lync' => false,
    'onenote' => false,
    'onedrive' => false,
    'outlook' => false,
    'powerpoint' => false,
    'publisher' => false,
    'teams' => false,
    'word' => false,
  },
```

Note: There are several combinations of configuration options,
test thoroughly before using in production.
