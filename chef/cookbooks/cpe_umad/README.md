cpe_umad Cookbook
========================
Installs and manages all components of [UMAD](https://github.com/erikng/umad) except for the embedded Python.framework

Requirements
------------

This cookbook depends on the following cookbooks

* cpe_launchd
* cpe_utils

The cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_umad']
* node['cpe_umad']['install']
* node['cpe_umad']['uninstall']
* node['cpe_umad']['manage_agents']
* node['cpe_umad']['custom_resources']
* node['cpe_umad']['la']
* node['cpe_umad']['la_identifier']
* node['cpe_umad']['ld_dep']
* node['cpe_umad']['ld_dep_identifier']
* node['cpe_umad']['ld_nag']
* node['cpe_umad']['ld_nag_identifier']

Notes
-----
This cookbook does not ship the `Python.framework` file found within the UMAD v2.0 codebase

This process will certainly be organization specific and you can utilize other tooling such as `cpe_remote_pkg` to install your own python (or the embedded python within the github).

You can enforce your own, custom python and shebang, pointing to your shipped python.

For example in your recipe you could do the following:

```
# Install python framework first
cpe_remote_pkg 'umad_python' do
  version '3.9.5'
  checksum '17e2f5cb361f7c30f7324d8b159086f4de5684afd676c41d81121b9b9ce2aab7'
  receipt 'org.macadmins.python.recommended'
end
# Setup cpe_umad
node.default['cpe_umad']'python_path'] = '/Library/ManagedFrameworks/Python/Python3.framework'
node.default['cpe_umad']['shebang'] = '#!/Library/ManagedFrameworks/Python/Python3.framework/Versions/Current/bin/python3'
```

Usage
-----
By default, this cookbook will not install UMAD or it's configuration

You will most certainly have to add the following screenshots in the `custom` directory:
- company_logo.png
- nag_ss.png
- uamdm_ss.png

If you set `node.default['cpe_umad']['custom_resources'] = true` you will need all _three_ pngs to be in the `custom` directory.

For example, you could tweak the below values:

node.default['cpe_umad']['install'] = true
node.default['cpe_umad']['custom_resources'] = true
node.default['cpe_umad']['manage_agents'] = true
node.default['cpe_umad']['la'] = {
  'limit_load_to_session_type' => [
    'Aqua',
  ],
  'program_arguments' => [
    '/Library/Application Support/umad/Resources/umad',
    '--cutoffdate',
    '2018-12-31-17:00',
    '--duedatetext',
    'MDM Enrollment is required by 12/31/2018 (No Restart Required)',
    '--paragraph2',
    'If you do not enroll into MDM you may lose the ability to connect to '\
    'Managed Software Center.',
    '--paragraph3',
    'To enroll, just look for the below notification, and click Details. '\
    'Once prompted, log in with your username and password.',
    '--profileidentifier',
    '0BAA07E9-ECF7-424C-A99E-8971AF62C4AD',
    '--subtitletext',
    'A friendly reminder from your CPE team',
    '--sysprefsh2text',
    'Open System Preferences and approve the MDM Device Profile.',
    '--titletext',
    'macOS MDM Enrollment',
    '--uamdmparagraph3',
    'Please go to System Preferences -> Profiles, click on the MDM '\
    'profile and click on the approve button.',
    '--manualenrollmenturl',
    'https://apple.com',
    '--moreinfourl',
    'https://google.com',
    '--cutoffdatewarning',
    '3',
    '--timerinital',
    '1800',
    '--timerday3',
    '900',
    '--timerday1',
    '600',
    '--timerfinal',
    '60',
    '--timerelapsed',
    '5',
    '--timermdm',
    '5',
  ],
  'run_at_load' => true,
  'standard_out_path' => '/Library/Application Support/umad/Logs/umad.log',
  'standard_error_path' => '/Library/Application Support/umad/Logs/umad.log',
  'start_calendar_interval' => [
    {
      'Minute' => 0,
    },
    {
      'Minute' => 30,
    },
  ],
  'type' => 'agent',
}
