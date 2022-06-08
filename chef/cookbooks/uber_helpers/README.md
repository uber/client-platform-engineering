uber_helpers Cookbook
==================
This cookbook is where we keep all the common function / classes for use with chef.

This cookbook depends on the following cookbook:

* [cpe_utils](https://github.com/facebook/IT-CPE/tree/master/chef/cookbooks/cpe_utils)

This cookbook is offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

This cookbook also depends on the following tools

* [gnes](https://github.com/erikng/gnes)

The cookbook will function without gnes being installed onto the system, but we have found bugs with the underlying code. Deploying gnes is outside of the function of this cookbook, but could be a simple recipe. An example will be provided below.

Usage
-----
* node.at_least?
  Returns a boolean value stating whether one version is higher than second version

  ```
  if node.at_least?('10.10', '10.9')
    do_thing
  else
    do_other_thing
  end
  ```

* node.at_least_or_lower?
  Returns a boolean value stating whether one version is less than or equal to second version

  ```
  if node.at_least_or_lower?('10.10', '10.9')
    do_thing
  else
    do_other_thing
  end
  ```

* node.catalina?
  Returns a boolean value stating whether macOS is running a version of 10.15

  ```
  if node.catalina?
    do_thing
  else
    do_other_thing
  end
  ```

* node.date_at_least?
  Returns a boolean value stating whether the current date is greater than or equal to targeted date

  ```
  if node.date_at_least?('2019-10-23')
    do_thing
  else
    do_other_thing
  end
  ```

* node.date_passed?
  Returns a boolean value stating whether the current date is greater than targeted date

  ```
  if node.date_passed?('2019-10-23')
    do_thing
  else
    do_other_thing
  end
  ```

* node.el_capitan?
  Returns a boolean value stating whether macOS is running a version of 10.11

  ```
  if node.el_capitan?
    do_thing
  else
    do_other_thing
  end
  ```

* node.file_age_over_24_hours?
  Returns a boolean value stating whether a file is over 24 hours in age

  ```
  if node.file_age_over_24_hours?('/etc/chef/client.rb')
    do_thing
  else
    do_other_thing
  end
  ```

* node.greater_than?
  Returns a boolean value stating whether one version is higher than second version

  ```
  if greater_than?('10.10', '10.9')
    do_thing
  else
    do_other_thing
  end
  ```

* node.high_sierra?
  Returns a boolean value stating whether macOS is running a version of 10.13

  ```
  if node.high_sierra?
    do_thing
  else
    do_other_thing
  end
  ```

* node.kext_profile_contains_teamid?
  Returns a boolean value stating whether a kext profile contains an allowed team id

  ```
  if node.kext_profile_contains_teamid?('X9E956P446', 'com.uber.mdm.kernelextensions')
    do_thing
  else
    do_other_thing
  end
  ```

* node.less_than?
  Returns a boolean value stating whether one version is less than second version

  ```
  if less_than?('10.10', '10.9')
    do_thing
  else
    do_other_thing
  end
  ```

* node.logged_in_user
  Returns the currently logged in user for ubuntu machines

  ```
  if logged_in_user == 'someone'
    do_thing
  else
    do_other_thing
  end
  ```

* node.logged_on_user_registry
  Returns the currently logged in user via registry commands for windows machines

  ```
  if logged_on_user_registry == 'someone'
    do_thing
  else
    do_other_thing
  end
  ```

* node.macos_application_version
  Returns the specific version from an application's plist on macOS.

  ```
  if node.macos_application_version('/Applications/Safari.app/Contents/Info.plist', 'CFBundleShortVersionString') == '13.0.2'
    do_thing
  else
    do_other_thing
  end
  ```

* node.macos_package_installed?
  Returns a boolean value stating whether a specific macOS package is installed, specifying the version.

  ```
  if node.macos_package_installed?('com.example.pkg.identifier', '1.0')
    do_thing
  else
    do_other_thing
  end
  ```

* node.macos_package_present?
  Returns a boolean value stating whether a specific macOS package is installed.

  ```
  if node.macos_package_present?('com.example.pkg.identifier')
    do_thing
  else
    do_other_thing
  end
  ```

* node.mojave?
  Returns a boolean value stating whether macOS is running a version of 10.14

  ```
  if node.mojave?
    do_thing
  else
    do_other_thing
  end
  ```

* node.not_eql?
  Returns a boolean value stating whether one version is equal to another version

  ```
  if not_eql?('10.10', '10.9')
    do_thing
  else
    do_other_thing
  end
  ```

* node.parse_json?
  Returns a json in a ruby format. Useful for data manipulation

  ```
  if parse_json('/path/to/json')['key'] == 'value'
    do_thing
  else
    do_other_thing
  end
  ```

* node.profile_contains_content?
  Returns a boolean value stating whether a specific macOS profile contains content in the payload

  ```
  if node.profile_contains_content?('identifier \"com.apple.screensharing.agent\" and anchor apple', 'com.uber.mdm.tcc')
    do_thing
  else
    do_other_thing
  end
  ```

* node.profile_installed?(payload_type, conditional_value, mdm_type)
  Returns a boolean value stating whether a specific macOS device profile is installed. Profile can be looked up several ways

  ```
  if node.profile_installed?('ProfileDisplayName', 'Device Manager')
    do_thing
  else
    do_other_thing
  end

  if node.profile_installed?('ProfileIdentifier', 'com.uber.mdm.example')
    do_thing
  else
    do_other_thing
  end
  ```

  Due to how Workspace One handles profiles, it makes it a bit harder to determine if a profile is installed. By passing the mdm_type of `ws1`, you can invoke a different logic pattern

  ```
  if node.profile_installed?('ProfileDisplayName', 'Intelligent Hub Privacy Preferences', 'ws1')
    do_thing
  else
    do_other_thing
  end
  ```

* node.sierra?
  Returns a boolean value stating whether macOS is running a version of 10.12

  ```
  if node.sierra?
    do_thing
  else
    do_other_thing
  end
  ```

* node.user_profile_installed?(payload_type, conditional_value, mdm_type)
  Returns a boolean value stating whether a specific macOS user profile is installed. Profile can be looked up several ways

  ```
  if node.user_profile_installed?('ProfileDisplayName', 'User Profile')
    do_thing
  else
    do_other_thing
  end

  if node.user_profile_installed?('ProfileIdentifier', 'com.uber.mdm.userprofileexample')
    do_thing
  else
    do_other_thing
  end
  ```

  Due to how Workspace One handles profiles, it makes it a bit harder to determine if a profile is installed. By passing the mdm_type of `ws1`, you can invoke a different logic pattern

  ```
  if node.user_profile_installed?('ProfileDisplayName', 'Airwatch Verification Profile for Mac devices', 'ws1')
    do_thing
  else
    do_other_thing
  end
  ```

* node.win_min_package_installed?
  Returns a boolean value stating whether a specific windows package is installed with a minimum version

  ```
  if node.win_min_package_installed?('Workspace ONE Intelligent Hub', '18.11.0.0')
    do_thing
  else
    do_other_thing
  end
  ```

* node.win_min_package_installed?
  Returns a boolean value stating whether a specific windows package is installed with a maximum version

  ```
  if node.win_max_package_installed?('Workspace ONE Intelligent Hub', '18.11.0.0')
    do_thing
  else
    do_other_thing
  end
  ```

* node.debian_min_package_installed?
  Returns a boolean value stating whether a specific Debian package is installed with a minimum version

  ```
  if debian_min_package_installed?('slack-desktop', '4.3.2')
    do_thing
  else
    do_other_thing
  end
  ```

  * node.ventura?
  Returns a boolean value stating whether macOS is running a version of 13.0

  ```
  if node.ventura?
    do_thing
  else
    do_other_thing
  end
  ```

* node.write_contents_to_file
  Helper function to write contents to a file

  ```
  json_contents = {
    'key' => 'value',
  }
  example_pretty_json = node.write_contents_to_file('/a/path', Chef::JSONCompat.to_json_pretty(json_contents))
  ```

* node.ws1_min_profile_installed?(profile_name, version)
  Returns a boolean value stating whether a specific Workspace One device profile is installed with the minimum required version.

  ```
  if node.ws1_min_profile_installed?('Intelligent Hub Privacy Preferences', 1)
    do_thing
  else
    do_other_thing
  end
  ```

* node.ws1_min_user_profile_installed?(profile_name, version)
  Returns a boolean value stating whether a specific Workspace One user profile is installed with the minimum required version.
  ```
  if node.ws1_min_user_profile_installed?('Airwatch Verification Profile for Mac devices', 1)
    do_thing
  else
    do_other_thing
  end
  ```

* node.yosemite?
  Returns a boolean value stating whether macOS is running a version of 10.10

  ```
  if node.yosemite?
    do_thing
  else
    do_other_thing
  end
  ```

# Example of installing external dependencies
Example of simple gnes deployment
```
gnes_receipt = 'com.github.erikng.gnes'
gnes_version = '0.0.1.80648'

# If gnes goes missing, either by accident or abuse, trigger re-install
unless ::File.exist?('/usr/local/bin/gnes')
  execute "/usr/sbin/pkgutil --forget #{gnes_receipt}" do
    not_if { shell_out("/usr/sbin/pkgutil --pkg-info #{gnes_receipt}").error? }
  end
end

cpe_remote_pkg 'gnes' do
  app 'gnes'
  pkg_name "gnes-#{gnes_version}"
  allow_downgrade false
  checksum 'ea6c09ee92d2611e8f38970ddeace7d51c322598fe470af31457f9355ad0d8d7'
  receipt gnes_receipt
  version gnes_version
end
```
