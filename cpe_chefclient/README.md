cpe_chefclient cookbook
====================
Configures chef client settings


Attributes
----------
```
node['cpe_chefclient']
node['cpe_chefclient']['configure'] # Bool
node['cpe_chefclient']['unmanage'] # Bool
node['cpe_chefclient']['path'] # String
node['cpe_chefclient']['config'] # Hash
```

For more details on availabe `config` options, see [client.rb](https://docs.chef.io/config_rb_client.html).


Usage
----
By default, this cookbook will not manage chef. This cookbook can manage multiple chef confgs if so desired.  The name of the key for the specified config will be written to disk in the default chef config directory.

Here is an example config:
### macOS
```ruby

node.default['cpe_chefclient']['configure'] = true
node.default['cpe_chefclient']['config']['client']  = {
  'chef' =>  {
    'log_level' => ':info',
    'chef_server_url' => 'https://chef.company.com/organizations/your-org',
    'validation_client_name' => 'your-org-validator',
    'validation_key' => '/etc/chef/your-org-validator.pem',
    'node_name' => node.serial, # Probably want to set this dynamically
    'automatic_attribute_whitelist' => [
      'hostname',
      'ipaddress',
      'macaddress',
      'machinename',
      'ohai_time',
      'platform',
      'platform_version',
    ],
  },
  'ohai' => {
    'plugin_path' => '/etc/chef/ohai/plugins',
    'disabled_plugins' => [':Azure', ':Cloud'],
    'directory' => '/etc/chef/ohai/plugins',
    'log_location' => '/etc/chef/ohai/plugins',
    'hints_path' => '/etc/chef/ohai/plugins',
  }
}
```

This would result in `/etc/chef/client.rb` with the contents as defined above.
