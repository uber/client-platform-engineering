cpe_nudge Cookbook
========================
Installs and manages all components of [nudge](https://github.com/erikng/nudge) except for the embedded Python.framework

Requirements
------------

This cookbook depends on the following cookbooks

* cpe_launchd
* cpe_utils

The cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_nudge']
* node['cpe_nudge']['install']
* node['cpe_nudge']['uninstall']
* node['cpe_nudge']['manage_la']
* node['cpe_nudge']['custom_resources']
* node['cpe_nudge']['la']
* node['cpe_nudge']['la_identifier']

Notes
-----
This cookbook does not ship the `Python.framework` file found within the nudge v2.0 codebase

This process will certainly be organization specific and you can utilize other tooling such as `cpe_remote_pkg` to install your own python (or the embedded python within the github).

You can enforce your own, custom python and shebang, pointing to your shipped python.

For example in your recipe you could do the following:

```
# Install python framework first
cpe_remote_pkg 'nudge_python' do
  version '3.8.0'
  checksum 'ef52f595c6046f8ce75bd48d57af9d16972125b60318763c90712b8d9c8d51c5'
  receipt 'com.org.pkg.nudge.python'
end
# Setup cpe_nudge
node.default['cpe_nudge']'python_path'] = '/Library/cpe/frameworks/Python.framework'
node.default['cpe_nudge']['shebang'] = '#!/Library/cpe/frameworks/Python.framework/Versions/3.8/bin/python3'
```

Usage
-----
By default, this cookbook will not install nudge or it's configuration

You will most certainly have to add the following screenshots in the `custom` directory:
- company_logo.png
- update_ss.png

If you set `node.default['cpe_nudge']['custom_resources'] = true` you will need _both_ pngs to be in the `custom` directory.

For example, you could tweak the below values:

node.default['cpe_nudge']['install'] = true
node.default['cpe_nudge']['custom_resources'] = true
node.default['cpe_nudge']['manage_la'] = true
node.default['cpe_nudge']['la'] = {
  'limit_load_to_session_type' => [
    'Aqua',
  ],
  'program_arguments' => [
    '/Library/Application Support/nudge/Resources/nudge',
  ],
  'run_at_load' => true,
  'standard_out_path' =>
    '/Library/Application Support/nudge/Logs/nudge.log',
  'standard_error_path' =>
    '/Library/Application Support/nudge/Logs/nudge.log',
  'start_calendar_interval' => [
    {
      'Minute' => 15, # run every hour on the 15th minute
    },
    {
      'Minute' => 45, # run every hour on the 45th minute
    },
  ],
  'type' => 'agent',
}
node.default['cpe_nudge']['json_prefs'] = {
  'preferences' => {
    'button_title_text' => 'Ready to start the update?',
    'button_sub_titletext' => 'Click on the button below.',
    'cut_off_date' => '2018-12-01-00:00',
    'cut_off_date_warning' => 3,
    'days_between_notifications' => 0,
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
    'path_to_app' => '/Applications/Install macOS Mojave.app',
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
node.default['cpe_nudge']['manage_json'] = true
