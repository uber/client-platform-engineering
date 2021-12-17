cpe_ssh_server Cookbook
========================
Manages state of SSH Server


Attributes
----------
* node['cpe_ssh_server']
* node['cpe_ssh_server']['manage']
* node['cpe_ssh_server']['enable']

Usage
-----
By default, this cookbook will not manage ssh server in any capacity. You may enable management of these things using by setting `enable` or `disable` to true


An example config would be:
```
    # Enforcing SSH On
    node.default['cpe_ssh_server']['manage'] = true
    node.default['cpe_ssh_server']['enable'] = true

    # Enforcing SSH Off
    node.default['cpe_ssh_server']['manage'] = true
```
