cpe_sal Cookbook
========================
Installs Sal, manages config and installs plugin scripts.

This cookbook depends on the following cookbooks

* cpe_launchd
* cpe_profiles
* cpe_remote
* cpe_utils

The cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_sal']
* node['cpe_sal']['config']
* node['cpe_sal']['configure']
* node['cpe_sal']['gosal_dir']
* node['cpe_sal']['install']
* node['cpe_sal']['manage_plugins']
* node['cpe_sal']['plugins']
* node['cpe_sal']['scripts_pkg']
* node['cpe_sal']['task']

Notes
-----
By default, this cookbook will use `cpe_remote` to install Sal. If you do not have this configured, your chef run may fail.

Usage
-----
By default, this cookbook will not install Sal, its preferences or any plugins. You may enable management of each of these things individually (Pkg, Config and Plugins).

The profile will manage the `com.github.salopensource.sal` preference domain.

The profile's organization key defaults to `Uber` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload for the above keys in `node['cpe_sal']`.

For plugin scripts, set the name of the plugin folder (Capialized) and script under the `plugins` attribute and place the script in `cpe_sal/files/default/`. These will automatically be installed and cleaned up if the management keys are removed.

For example, a sane default configuration would be:

### macOS
```ruby
node.default['cpe_sal']['configure'] = true
node.default['cpe_sal']['config']['ServerURL'] = 'https://MYSALSERVER/'
node.default['cpe_sal']['config']['GetOhai'] = true
node.default['cpe_sal']['config']['key'] = 'MYKEY'

node.default['cpe_sal']['install'] = true
node.default['cpe_sal']['scripts_pkg'] = {
  'name' => 'sal_scripts',
  'version' => '2.1.3',
  'checksum' =>
    'cc3ceee8bd0d2eb62fffc4058bcec25941abc7b190d76cf97316fc2d2bf49a8c',
  'receipt' => 'com.github.salopensource.sal_scripts',
  'url' => 'https://MYSERVER/sal_scripts.pkg'
}

node.default['cpe_sal']['manage_plugins'] = true
node.default['cpe_sal']['plugins'] = {
  'Myplugin' => 'myplugin.py'
}
```


### Windows
```ruby
node.default['cpe_sal']['gosal_dir'] = 'C:\\ProgramData\\sal'
node.default['cpe_sal']['scripts_pkg'] = {
  'name' => 'gosal',
  'checksum' =>
    '38001bdffda77cb73899c235ec82cb20dee0fef9890bc94c35a742dc7849c6b9',
  'version' => '1.0'
}
node.default['cpe_sal']['config']['management'] = {
  'tool' => 'chef',
  'path' => 'C:\\opscode\\chef\\bin\\ohai.bat',
  'command' => ''
}
```
