cpe_osquery Cookbook
========================
Installs osquery, manages options via osquery.flags, manages services and can uninstall/cleanup the osquery install.

This cookbook depends on the following cookbooks

* cpe_remote
* cpe_utils

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Note: You *must* have Chocolatey installed on Windows before running this cookbook. It does not need to be configured or have a server, it only needs to be present.

Attributes
----------
* node['cpe_osquery']
* node['cpe_osquery']['conf']
* node['cpe_osquery']['extensions']
* node['cpe_osquery']['install']
* node['cpe_osquery']['manage']
* node['cpe_osquery']['manage_official_packs']
* node['cpe_osquery']['official_packs_install_list']
* node['cpe_osquery']['options']
* node['cpe_osquery']['packs']
* node['cpe_osquery']['pkg']
* node['cpe_osquery']['pkg']['checksum']
* node['cpe_osquery']['pkg']['name']
* node['cpe_osquery']['pkg']['receipt']
* node['cpe_osquery']['pkg']['version']
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

To deploy extensions, you would do something like the following:
```
if debian?
  node.default['cpe_osquery']['extensions']['macadmins'] = {
    'checksum' => '4836a25fbc3ab3153464f09d07da14a622fd264aa7e3f764c1788cf29b6ec348',
    'version' => '0.0.7',
  }
elsif macos?
  node.default['cpe_osquery']['extensions']['macadmins'] = {
    'checksum' => 'e84910046705f98dc7a30c5ffce033d1eebfb3ee4c9334a01dc869f5fbab79f5',
    'version' => '0.0.7',
  }
elsif windows?
  node.default['cpe_osquery']['extensions']['macadmins'] = {
    'checksum' => '0429e50ac58f7467be11c078f624aa12dfbadc4fba0cf13a39b3bd006643a9b8',
    'version' => '0.0.7',
  }
end
```

cpe_osquery will use some opinionated paths and there is an expectation that your extensions url will follow a specific format

```
ls -1 /cdn/osquery
extensions/
osquery-5.2.2.deb
osquery-5.2.2.msi
osquery-5.2.2.pkg

ls -1 /cdn/osquery/extensions
debian/
mac_os_x/
windows/

ls -1 /cdn/osquery/extensions/debian
macadmins-0.0.7

ls -1 /cdn/osquery/extensions/mac_os_x
macadmins-0.0.7

ls -1 /cdn/osquery/extensions/windows
macadmins-0.0.7
```

Extensions will be installed as `.ext` for debian and linux and `.exe` for windows


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
  unless windows? # Windows automatically inherits from the parent
    owner root_owner
    group node['root_group']
    mode '0700'
  end
  notifies :restart, "service[#{service_name}]"
end
node.default['cpe_osquery']['extensions'] = [
  ext_path,
]
```

If you would like to install query packs, configure something like the following. Please note that cpe_osquery installs the packs as JSON conf files, not yaml.
```
if macos?
  {
    'Example Query' => {
      'description' => 'This is an example query for macOS only.',
      'interval' => 86400,
      'query' => 'SELECT * from apps;',
    },
  }.each do |k, v|
    node.default['cpe_osquery']['packs']['example-pack']['queries'][k] = v
  end
end
```

If you do not need query packs or would also like to configure distributed queries, configure the `schedule` key in the `cpe_osquery['conf']` hash.
```
if macos?
  {
    'Example Distributed Query' => {
      'description' => 'This is an example distributed query for macOS only.',
      'interval' => 86400,
      'query' => 'SELECT * from apps;',
    },
  }.each do |k, v|
    node.default['cpe_osquery']['conf']['schedule'][k] = v
  end
end
```

If you want to manage the official packs that come loaded with the osquery package, you would configure something like the following. Please see the `official_pack_list` code function in the `cpe_osquery` resource for the list of names accepted by the cookbook.
```
node.default['cpe_osquery']['manage_official_packs'] = true
node.default['cpe_osquery']['official_packs_install_list'] = [
  'it-compliance',
  'vuln-management',
]
```

If you want to delete all official packs bundled with the osquery package, just manage the official packs and use the built-in empty array.

```
node.default['cpe_osquery']['manage_official_packs'] = true
```
