cpe_nudge Cookbook
========================
Installs and manages all components of [nudge](https://github.com/macadmins/nudge) and [nudge-python](https://github.com/macadmins/nudge-python).

## Requirements
------------

This cookbook depends on the following cookbooks

* cpe_launchd
* cpe_remote
* cpe_utils
* uber_helpers

The non-Uber cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

## Attributes
----------
* node['cpe_nudge']
* node['cpe_nudge']['nudge-python']['base_path']
* node['cpe_nudge']['nudge-python']['custom_resources']
* node['cpe_nudge']['nudge-python']['install']
* node['cpe_nudge']['nudge-python']['json_path']
* node['cpe_nudge']['nudge-python']['json_prefs']
* node['cpe_nudge']['nudge-python']['launchagent']
* node['cpe_nudge']['nudge-python']['launchagent_identifier']
* node['cpe_nudge']['nudge-python']['manage_json']
* node['cpe_nudge']['nudge-python']['manage_launchagent']
* node['cpe_nudge']['nudge-python']['python_path']
* node['cpe_nudge']['nudge-python']['uninstall']
* node['cpe_nudge']['nudge-swift']['app_path']
* node['cpe_nudge']['nudge-swift']['base_path']
* node['cpe_nudge']['nudge-swift']['custom_resources']
* node['cpe_nudge']['nudge-swift']['install']
* node['cpe_nudge']['nudge-swift']['json_path']
* node['cpe_nudge']['nudge-swift']['json_prefs']
* node['cpe_nudge']['nudge-swift']['launchagent']
* node['cpe_nudge']['nudge-swift']['launchagent_identifier']
* node['cpe_nudge']['nudge-swift']['loggerdaemon']
* node['cpe_nudge']['nudge-swift']['loggerdaemon_identifier']
* node['cpe_nudge']['nudge-swift']['manage_json']
* node['cpe_nudge']['nudge-swift']['manage_launchagent']
* node['cpe_nudge']['nudge-swift']['manage_loggerdaemon']
* node['cpe_nudge']['nudge-swift']['manage_pkg']
* node['cpe_nudge']['nudge-swift']['pkg']
* node['cpe_nudge']['nudge-swift']['uninstall']

## Notes
-----
There are now two versions of Nudge: Nudge-Python and Nudge-Swift.

## Usage
-----
By default, this cookbook will not install nudge or it's configuration

### Python-Swift Usage
-----
You will most certainly have to add the following screenshots in the `custom` directory:
- logoDark.png
- logoLight.png
- screenShotDark.png
- screenShotLight.png

If you set `node.default['cpe_nudge']['nudge-swift']['custom_resources'] = true` you will need _all_ pngs to be in the `custom` directory.

### Python-Swift Notes
-----

The following is an example of what you could do

```ruby
node.default['cpe_nudge']['nudge-swift']['install'] = true
node.default['cpe_nudge']['nudge-swift']['custom_resources'] = true
node.default['cpe_nudge']['nudge-swift']['manage_launchagent'] = true
node.default['cpe_nudge']['nudge-swift']['manage_loggerdaemon'] = true
node.default['cpe_nudge']['nudge-swift']['manage_json'] = true

# Install the Package via GitHub
node.default['cpe_nudge']['nudge-swift']['manage_pkg'] = true
node.default['cpe_nudge']['nudge-swift']['pkg']['checksum'] =
  'bd2d389634f502bb632e4d4bb84ee4713608c18aff4e842e1893d09072b86c12'
node.default['cpe_nudge']['nudge-swift']['pkg']['version'] = '1.0.0.02222021220640'
# Don't do this in production, it's just an example
node.default['cpe_nudge']['nudge-swift']['pkg']['url'] =
  'https://github.com/macadmins/nudge/releases/download/v.1.0.0.02222021220640/Nudge-1.0.0.02222021220640.pkg'

# Preferences
node.default['cpe_nudge']['nudge-swift']['json_prefs'] = {
  'osVersionRequirements' => [
    {
      'aboutUpdateURL' => 'https://github.com/macadmins/nudge',
      'majorUpgradeAppPath' => '/Applications/Install macOS Big Sur.app',
      'requiredInstallationDate' => '2021-02-28T00:00:00Z',
      'requiredMinimumOSVersion' => '11.2.1',
      'targetedOSVersions' => [
        '11.0',
        '11.0.1',
        '11.1',
        '11.2',
      ],
    },
  ],
  'userInterface' => {
    'iconDarkPath' => '/Library/Application Support/Nudge/logoDark.png',
    'iconLightPath' => '/Library/Application Support/Nudge/logoLight.png',
    'forceFallbackLanguage' => true,
    'screenShotDarkPath' => '/Library/Application Support/Nudge/screenShotDark.png',
    'screenShotLightPath' => '/Library/Application Support/Nudge/screenShotLight.png',
    'updateElements' => [
      {
        '_language' => 'en',
        'subHeader' => 'A friendly reminder from your local CPE team',
      },
    ],
  },
}
```

### Python-Nudge Usage
-----
You will most certainly have to add the following screenshots in the `custom` directory:
- company_logo.png
- update_ss.png

If you set `node.default['cpe_nudge']['nudge-python']['custom_resources'] = true` you will need _both_ pngs to be in the `custom` directory.

### Python-Nudge Notes
-----
For Nudge-Python, [macadmins/python(https://github.com/macadmins/python)] is a depedency. This cookbook does not configure or install that package.

This process will certainly be organization specific and you can utilize other tooling such as `cpe_remote_pkg` to install the required python dependencies.

The following is an example of what you could do
```ruby
# Macadmins Python
receipt = 'org.macadmins.python.recommended'

# If the Python Framework goes missing, either by accident or abuse, trigger re-install
unless ::Dir.exist?('/Library/ManagedFrameworks/Python/Python3.framework')
  execute "/usr/sbin/pkgutil --forget #{receipt}" do
    not_if { shell_out("/usr/sbin/pkgutil --pkg-info #{receipt}").error? }
  end
end

# Install the Python framework
cpe_remote_pkg 'Macadmin Python (Recommended)' do
  app 'macadmins_python'
  pkg_name "python_recommended_signed-#{version}"
  allow_downgrade false
  checksum checksum
  receipt '3.9.1.12152020184251'
  version '32cfe8f261d184a8b0fc349cf76838978b6aff8fa5a684f0087809ca2fafef36'
end
```

For example, you could tweak the below values:

```ruby
node.default['cpe_nudge']['nudge-python']['install'] = true
node.default['cpe_nudge']['nudge-python']['custom_resources'] = true
node.default['cpe_nudge']['nudge-python']['manage_launchagent'] = true

# Preferences
node.default['cpe_nudge']['nudge-python']['manage_json'] = true
node.default['cpe_nudge']['nudge-python']['json_prefs'] = {
  'preferences' => {
    'button_title_text' => 'Ready to start the update?',
    'button_sub_titletext' => 'Click on the button below.',
    'cut_off_date' => '2018-12-01-00:00',
    'cut_off_date_warning' => 3,
    'days_between_notifications' => 0,
    'dismissal_count_threshold' => 100,
    'main_subtitle_text' => 'A friendly reminder from your local CPE team',
    'main_title_text' => 'macOS Update',
    'minimum_os_version' => '10.14.2',
    'more_info_url' =>
      'https://somewhere.tld',
    'paragraph1_text' =>
      'A fully up-to-date device is required to ensure that IT can your '\
      'accurately protect your computer.',
    'paragraph2_text' =>
      'If you do not update your computer, you may lose access to some '\
      'items necessary for your day-to-day tasks.',
    'paragraph3_text' =>
      'To begin the update, simply click on the button below and follow '\
      'the provided steps.',
    'paragraph_title_text' =>
      'A security update is required on your machine.',
    'path_to_app' => '/Applications/Install macOS Big Sur.app',
    'random_delay' => true,
    'timer_day_1' => 600,
    'timer_day_3' => 900,
    'timer_elapsed' => 300,
    'timer_final' => 300,
    'timer_initial' => 1800,
    'update_minor' => true,
    'update_minor_days' => 14,
  },
  'software_updates' => [],
}
```
