cpe_chefctl cookbook
====================
Chefctl is a script used to run `chef-client`. It enables the use of pre/post flight hooks and several other niceties for running chef.

Used to configure [chefctl](https://github.com/facebook/chef-utils/tree/master/chefctl)


Attributes
----------
```
node['cpe_chefctl']
node['cpe_chefctl']['configure'] # Bool
node['cpe_chefctl']['remove'] # Bool
node['cpe_chefctl']['config'] # Bool
node['cpe_chefctl']['config']['color'] # Bool
node['cpe_chefctl']['config']['verbose'] # Bool
node['cpe_chefctl']['config']['chef_client'] # String
node['cpe_chefctl']['config']['debug'] # Bool
node['cpe_chefctl']['config']['chef_options'] # Array
node['cpe_chefctl']['config']['human'] # Bool
node['cpe_chefctl']['config']['immediate'] # Bool
node['cpe_chefctl']['config']['lock_file'] # String
node['cpe_chefctl']['config']['lock_time'] # Int
node['cpe_chefctl']['config']['log_dir'] # String
node['cpe_chefctl']['config']['quiet'] # Bool
node['cpe_chefctl']['config']['splay'] # Int
node['cpe_chefctl']['config']['max_retries'] # Int
node['cpe_chefctl']['config']['testing_timestamp'] # String
node['cpe_chefctl']['config']['whyrun'] # Bool
node['cpe_chefctl']['config']['plugin_path'] # String
node['cpe_chefctl']['config']['path'] # Array
node['cpe_chefctl']['config']['symlink_output'] # Bool
node['cpe_chefctl']['config']['passthrough_env'] # Array
```

For more details on availabe `config` options, see [chefctl.rb](https://github.com/facebook/chef-utils/blob/master/chefctl/src/chefctl.rb#L122-L206).
