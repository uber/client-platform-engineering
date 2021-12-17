cpe_gorilla Cookbook
============================
Configures and installs gorilla

Requirements
------------
* Windows
* [Gorilla](https://github.com/1dustindavis/gorilla)

This cookbook depends on the following cookbooks

* cpe_remote
* cpe_utils

The cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Notes
------------
Gorilla is a tool for installing windows packages, similar to [Munki](https://github.com/munki/munki).

This cookbook assumes that you are installing the executable (.exe) version of Gorilla, not the MSI (.msi) version.

You can find executable releases of Gorilla [here](https://github.com/1dustindavis/gorilla/releases)

By default, we assign a manifest for a given role (i.e. dev, qa, production) node['cpe_gorilla']['preferences']['manifest'] => 'dev'.
A manifest defines the list of applications which should be installed for a given role.

Individual or group-based installs can be pushed ad-hoc by using the local manifest (e.g. node['cpe_gorilla']['local_manifest']['managed_installs'] << 'some_application')


Attributes
----------
* node['cpe_gorilla']
* node['cpe_gorilla']['dir']
* node['cpe_gorilla']['exe']
* node['cpe_gorilla']['install']
* node['cpe_gorilla']['preferences']
* node['cpe_gorilla']['task']
* node['cpe_gorilla']['task']['create_task']
* node['cpe_gorilla']['uninstall']
* node['cpe_gorilla']['local_manifest']

For an authoritative list of preferences, please see [Gorilla's Client Configuration](https://github.com/1dustindavis/gorilla/wiki/Client-Configuration)

This cookbook assumes you are using the executable version of Gorilla and not the MSI provided with v1.0.0 beta1 and higher. An example of this format can be found [here](https://github.com/1dustindavis/gorilla/releases/download/v1.0.0-beta.2/gorilla.exe)
