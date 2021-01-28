cpe_anyconnect Cookbook
========================
Installs anyconnect with ChoiceChanges.xml and installs all necessary files for anyconnect to properly configure itself during install.

For information on how to create the ChoiceChanges.xml file please see [the munki documentation](https://github.com/munki/munki/wiki/ChoiceChangesXML)

For more information on the AnyConnect ChoiceChanges see [this blog post](https://sneakypockets.wordpress.com/2017/07/26/using-installer-choices-xml-to-modify-anyconnect-and-mcafee-deployments/)

This cookbook depends on the following cookbooks

* cpe_remote
* cpe_utils

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_anyconnect']
* node['cpe_anyconnect']['app_path']
* node['cpe_anyconnect']['install']
* node['cpe_anyconnect']['la_gui_identifier']
* node['cpe_anyconnect']['manage']
* node['cpe_anyconnect']['pkg']
* node['cpe_anyconnect']['pkg']['allow_downgrade']
* node['cpe_anyconnect']['pkg']['app_name']
* node['cpe_anyconnect']['pkg']['cache_path']
* node['cpe_anyconnect']['pkg']['checksum']
* node['cpe_anyconnect']['pkg']['receipt']
* node['cpe_anyconnect']['pkg']['version']
* node['cpe_anyconnect']['uninstall']

A base install config might look like this
```
node.default['cpe_anyconnect']['pkg']['version'] = '4.9.04053'
node.default['cpe_anyconnect']['pkg']['checksum'] = 'b62390cd1aff4484f27ddc12ca864389b9f4c03eb76e2ccf673b27f16f06a795'
node.default['cpe_anyconnect']['install'] = true
node.default['cpe_anyconnect']['manage'] = true
```
