cpe_crowdstrike_falcon_sensor Cookbook
========================
Installs crowdstrike, manages config and services.

This cookbook depends on the following cookbooks

* cpe_remote
* cpe_launchd
* cpe_utils

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_crowdstrike_falcon_sensor']
* node['cpe_crowdstrike_falcon_sensor']['agent']
* node['cpe_crowdstrike_falcon_sensor']['agent']['customer_id']
* node['cpe_crowdstrike_falcon_sensor']['agent']['falconctl_path']
* node['cpe_crowdstrike_falcon_sensor']['agent']['registration_token']
* node['cpe_crowdstrike_falcon_sensor']['agent']['server_url']
* node['cpe_crowdstrike_falcon_sensor']['install']
* node['cpe_crowdstrike_falcon_sensor']['manage']
* node['cpe_crowdstrike_falcon_sensor']['pkg']
* node['cpe_crowdstrike_falcon_sensor']['pkg']['app_name']
* node['cpe_crowdstrike_falcon_sensor']['pkg']['checksum']
* node['cpe_crowdstrike_falcon_sensor']['pkg']['mac_osx_pkg_receipt']
* node['cpe_crowdstrike_falcon_sensor']['pkg']['uninstall_checksum']
* node['cpe_crowdstrike_falcon_sensor']['pkg']['uninstall_version']
* node['cpe_crowdstrike_falcon_sensor']['pkg']['version']
* node['cpe_crowdstrike_falcon_sensor']['uninstall']

A base install config might look like this
```
# Global Values
node.default['cpe_crowdstrike_falcon_sensor']['install'] = true
node.default['cpe_crowdstrike_falcon_sensor']['pkg']['app_name'] =
  'crowdstrike_falcon_sensor'
{
  'customer_id' => 'astring',
  'registration_token' => 'a string',
  'server_url' => 'https://somewhere.tld',
}.each do |k, v|
  node.default['cpe_crowdstrike_falcon_sensor']['agent'][k] = v
end

if node.debian_family?
  {
    'checksum' => 'a26f476f8d9360d754b254da9a22088a3f16b9425ff6ff913989aa2264'\
    '086c73',
    'version' => '4.25.7103.0',
  }.each do |k, v|
    node.default['cpe_crowdstrike_falcon_sensor']['pkg'][k] = v
  end
elsif node.macos?
  # Don't install Crowdstrike on 10.11 and lower as it's unsupported.
  if node.os_at_least?(10.12)
    {
      'checksum' => '9039f2e654133a4b760c929c724c149aabe8f9315616be5e02e893102'\
      'f77add2',
      'version' => '4.25.8705.0',
    }.each do |k, v|
      node.default['cpe_crowdstrike_falcon_sensor']['pkg'][k] = v
    end
  end
elsif node.windows?
  {
    'checksum' => '5ec64710ee3df9da3a3370144ca080624be03978dd53ef7ad8967088acc'\
    '6e87b',
    'version' => '4.25.8802.0',
    'uninstall_checksum' => 'e127f23dda6f2c3f48e9d2ad55a9d245b3fe6e6e607ed2572'\
    'a4dd2be819a8235',
    'uninstall_version' => '1.0',
  }.each do |k, v|
    node.default['cpe_crowdstrike_falcon_sensor']['pkg'][k] = v
  end
end
```
