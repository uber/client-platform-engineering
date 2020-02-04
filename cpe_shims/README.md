cpe_shims Cookbook
========================
Installs and managed shims for the purpose of extending small binaries

This cookbook depends on the following cookbook:

* cpe_utils

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_shims']
* node['cpe_shims']['manage']
* node['cpe_shims']['shims']
* node['cpe_shims']['shims']['name_of_shim']
* node['cpe_shims']['shims']['name_of_shim']['content']
* node['cpe_shims']['shims']['name_of_shim']['path']
* node['cpe_shims']['shims']['name_of_shim']['shebang']
* node['cpe_shims']['unmanage']

Notes
----------
While you technically could stuff an entire script into cpe_shims, it is **NOT RECOMMENDED**. Shims are small binaries that allow you to extend another binary, not complicated scripts.

Usage
----------
Laying down a config for `makecatalogs` (a component of [Munki](https://github.com/munki/munki) ) would look like this:

```
node.default['cpe_shims']['shims']['makecatalogs'] = {
  'content' =>
    '/usr/bin/python /usr/local/munki/makecatalogs',
  'path' => '/usr/local/bin/makecatalogs',
  'shebang' => '#!/bin/bash',
}
```
