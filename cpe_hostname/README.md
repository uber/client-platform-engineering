cpe_hostname Cookbook
========================
Enforces hostnames on devices

This cookbook depends on the following cookbooks

* cpe_utils

This cookbook is offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_hostname']
* node['cpe_hostname']['enforce']
* node['cpe_hostname']['hostname']

Usage
-----
A config for setting the hostname to username-serial:

```ruby
node.default['cpe_hostname']['enforce'] = true
if node.macos?
  node.default['cpe_hostname']['hostname'] =
    "#{node.console_user}-#{node.serial}"
end
```
