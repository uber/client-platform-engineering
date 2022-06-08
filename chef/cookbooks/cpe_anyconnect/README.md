cpe_anyconnect Cookbook
========================
Installs Cisco AnyConnect Client with `ChoiceChanges.xml` and installs all necessary files for AnyConnect to properly configure itself during install.

For information on how to create the ChoiceChanges.xml file please see [the munki documentation](https://github.com/munki/munki/wiki/ChoiceChangesXML)

For more information on the AnyConnect ChoiceChanges see [this blog post](https://sneakypockets.wordpress.com/2017/07/26/using-installer-choices-xml-to-modify-anyconnect-and-mcafee-deployments/)

For information about installing the AnyConnect client see [AnyConnect Deployment Overview](https://www.cisco.com/c/en/us/td/docs/security/vpn_client/anyconnect/anyconnect40/administration/guide/b_AnyConnect_Administrator_Guide_4-0/deploy-anyconnect.html#ID-1425-000002d6)

This cookbook depends on the following cookbook:

* cpe_remote

This cookbook is offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_anyconnect']
* node['cpe_anyconnect']['app_path']
* node['cpe_anyconnect']['desktop_shortcut']
* node['cpe_anyconnect']['install']
* node['cpe_anyconnect']['la_gui_identifier']
* node['cpe_anyconnect']['manage']
* node['cpe_anyconnect']['modules']['name']
* node['cpe_anyconnect']['modules']['display_name']
* node['cpe_anyconnect']['modules']['version']
* node['cpe_anyconnect']['modules']['checksum']
* node['cpe_anyconnect']['modules']['install_args']
* node['cpe_anyconnect']['backup_logs']
* node['cpe_anyconnect']['nslookup_failure_count_threshold']
* node['cpe_anyconnect']['organization_id']
* node['cpe_anyconnect']['pkg']
* node['cpe_anyconnect']['pkg']['allow_downgrade']
* node['cpe_anyconnect']['pkg']['app_name']
* node['cpe_anyconnect']['pkg']['cache_path']
* node['cpe_anyconnect']['pkg']['checksum']
* node['cpe_anyconnect']['pkg']['receipt']
* node['cpe_anyconnect']['pkg']['version']
* node['cpe_anyconnect']['profile_identifier']
* node['cpe_anyconnect']['umbrella_diagnostic_link']
* node['cpe_anyconnect']['uninstall']

A base install config might look like this
```
node.default['cpe_anyconnect']['pkg']['version'] = '4.9.04053'
node.default['cpe_anyconnect']['pkg']['checksum'] = 'b62390cd1aff4484f27ddc12ca864389b9f4c03eb76e2ccf673b27f16f06a795'
node.default['cpe_anyconnect']['install'] = true
node.default['cpe_anyconnect']['manage'] = true
```

An example of a Windows predeployment using specific modules would look like this
```
node.default['cpe_anyconnect']['pkg']['version'] = '4.9.04053'
node.default['cpe_anyconnect']['uninstall'] = true
node.default['cpe_anyconnect']['manage'] = true
node.default['cpe_anyconnect']['modules'] = [
  {
    'name' => 'core',
    'display_name' => 'Cisco AnyConnect Secure Mobility Client',
    'version' => '4.9.04053',
    'checksum' => 'c33b051cbaf0dc27410aa7899666fe02eee5a0b0d3957d2868822adf457a16ff',
    'install_args' => 'PRE_DEPLOY_DISABLE_VPN=1'
  },
  {
    'name' => 'dart',
    'display_name' => 'Cisco AnyConnect Diagnostics and Reporting Tool',
    'version' => '4.9.04053',
    'checksum' => 'a6a8e1d82a3681879af389e9d3bff97fbf971a7eb489bcf48b7bbfbf37e326f6',
  },
  {
    'name' => 'umbrella',
    'display_name' => 'Cisco AnyConnect Umbrella Roaming Security Module',
    'version' => '4.9.04053',
    'checksum' => '0fde953e3c3f4d33cfda63083f931ac5c67b447945fc61efcb0927d0eefc58cf',
  },
  {
    'name' => 'gina',
    'display_name' => 'Cisco AnyConnect Start Before Logon Module',
    'version' => '4.9.04053',
    'checksum' => 'dee58cc7a9d44db1afefd7fc3718237309a43e4491ce8a5d9b94b656189e63d7',
  },
]
node.default['cpe_anyconnect']['desktop_shortcut'] = true
```
An example of setting the nslookup_failure_count_threshold other than default (macOS only)
```
node.default['cpe_anyconnect']['nslookup_failure_count_threshold'] = 5
```
An example of setting the attribute backup_logs to trigger a log backup before directory deletion (macOS only)
```
node.default['cpe_anyconnect']['backup_logs'] = true
```
