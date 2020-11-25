cpe_ulimit Cookbook
=========================
The cookbook will deploy and manage a Launch Daemon for the use of open file descriptors. By default, it will use 256, which is the Apple OS default.

This cookbook depends on the following cookbooks.

* cpe_launchd

This cookbook is offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Requirements
------------
Mac OS X

Notes
------------
When testing on macOS 10.14.5, passing `unlimited` to the `maxfiles_hard_limit` is functionally equivalent to passing `10240`. This value could change, so it is recommended to keep it with the `unlimited` paramater.

Attributes
----------
* node['cpe_ulimit']
* node['cpe_ulimit']['manage']
* node['cpe_ulimit']['maxfiles_soft_limit']
* node['cpe_ulimit']['maxfiles_hard_limit']
* node['cpe_ulimit']['maxproc_soft_limit']
* node['cpe_ulimit']['maxproc_hard_limit']
* node['cpe_ulimit']['sysctl_maxfiles']

Usage
-----

Up the max files soft limit to 4096 and dynamic launchd label

    node.default['cpe_ulimit']['manage'] = true
    node.default['cpe_ulimit']['maxfiles_soft_limit'] = '4096'
    node.default['cpe_ulimit']['maxfiles_hard_limit'] = 'unlimited'
