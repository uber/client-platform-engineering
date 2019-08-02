cpe_osquery Cookbook
========================
Installs osquery, manages options via osquery.flags, manages services and can uninstall/cleanup the osquery install.

This cookbook depends on the following cookbooks

* cpe_remote
* cpe_utils

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_osquery']
* node['cpe_osquery']['install']
* node['cpe_osquery']['pkg']
* node['cpe_osquery']['pkg']['name']
* node['cpe_osquery']['pkg']['checksum']
* node['cpe_osquery']['pkg']['version']
* node['cpe_osquery']['pkg']['receipt']
* node['cpe_osquery']['manage']
* node['cpe_osquery']['options']
* node['cpe_osquery']['extensions']
* node['cpe_osquery']['uninstall']

Usage
-----
There are a few things that cpe_osquery assumes about the names of the installers on the remote server. You will need to rename all osquery installers to follow this naming scheme:

macOS:
osquery-3.3.2.pkg

Windows:
osquery-3.3.2.msi

Ubuntu/Debian:
osquery-3.3.2.deb

Additionally, you'll need to provide two additional pieces of information depending upon the platform:

1. The actual version of the Ubuntu/Debian pkg, which has dashes and other stuff in it. You can see an example of it in the `debian` pkg config below.
2. The pkg receipt for macOS

A base install config might look like this
```
# Global Values
node.default['cpe_osquery']['install'] = true
node.default['cpe_osquery']['pkg']['name'] = 'osquery'

osquery_pkg = value_for_platform_family(
  'windows' => {
    'checksum' => 'ce902f7880d116ef6e7f6919d679fa5d40bf45aa85c10505c8558d174' \
    '5d3204c',
    'version' => '3.3.2',
  },
  'debian' => {
    'checksum' => 'ce902f7880d116ef6e7f6919d679fa5d40bf45aa85c10505c8558d174' \
    '5d3204c',
    'version' => '3.3.2',
    'dpkg_version' => '3.3.2-1.linux', # Because the dpkg version is different
  },
  'mac_os_x' => {
    'checksum' => 'f9da953ede4f035de14471abf094ff4e71f404d6002765d3d27e38ba' \
    'dfeb0826',
    'version' => '3.3.2',
    'receipt' => 'com.facebook.osquery',
  }
  'default' => {},
)

node.default['cpe_osquery']['pkg'] = osquery_pkg
node.default['cpe_osquery']['manage'] = true
# All options can be found here: https://osquery.readthedocs.io/en/stable/installation/cli-flags/
node.default['cpe_osquery']['options'] = {
  'tls_hostname' => 'myserver.company.com',
  'tls_session_reuse' => true,
  'worker_threads' => 4,
}
```
You are responsible for placing the any custom extensions. You will want to do this via a cookbook_file cpe_remote_file, package or whatever makes sense in your deployment. Here is an example of what this might look like:

```
## Set service_name so we can notify it for a delayed restart on change
service_name = value_for_platform_family(
  'mac_os_x' => 'com.facebook.osqueryd',
  'debian' =>  'osqueryd.service',
  'windows' => 'osqueryd',
  'default' => nil,
)
ext_filename = 'my_ext.ext'
my_ext_hash = '350ff0b1061ca0d1e933c59861d6421ebb2667d494875fcb1821d3df44f08476'
ext_path = ::File.join('/path/to', ext_filename)
cpe_remote_file 'Install extension' do
  file_name ext_filename
  checksum my_ext_hash
  path ext_path
  unless node.windows? # Windows automatically inherits from the parent
    owner root_owner
    group root_group
    mode '0700'
  end
  notifies :restart, "service[#{service_name}]"
end
node.default['cpe_osquery']['extensions'] = [
  ext_path,
]
```
