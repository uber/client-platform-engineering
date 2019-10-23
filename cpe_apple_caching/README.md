cpe_apple_caching Cookbook
========================
Manages and configures apple caching service

This cookbook depends on the following cookbooks

* cpe_utils

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_apple_caching']
* node['cpe_apple_caching']['configure']
* node['cpe_apple_caching']['force_disable']
* node['cpe_apple_caching']['prefs']

Forcing caching server to disable
```
node.default['cpe_apple_caching']['force_disable'] = true
```

Disabling personal caching only and configure device
```
node.default['cpe_apple_caching']['configure'] = true
{
  'AllowPersonalCaching' => true,
}.each do |k, v|
  node.default['cpe_apple_caching']['prefs'][k] = v
end
```
