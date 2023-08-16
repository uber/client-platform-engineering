cpe_appstream Cookbook
========================
This cookbook utilizes AWS's Image Builder application

This cookbook depends on the following cookbooks

* cpe_utils

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_appstream']
* node['cpe_appstream']['install']
* node['cpe_appstream']['image_assistant_path']
* node['cpe_appstream']['image_builder_tag']
* node['cpe_appstream']['applications']['name']
* node['cpe_appstream']['applications']['display_name']
* node['cpe_appstream']['applications']['path']
* node['cpe_appstream']['applications']['working_dir']
* node['cpe_appstream']['applications']['manifest_path']
* node['cpe_appstream']['image']['name']
* node['cpe_appstream']['image']['description']
* node['cpe_appstream']['image']['display_name']
* node['cpe_appstream']['image']['enable_dynamic_app_catalog']
* node['cpe_appstream']['image']['use_latest_agent_version']
* node['cpe_appstream']['image']['tags']
* node['cpe_appstream']['image']['name']


Usage
---
* node['cpe_appstream']['image_builder_tag'] specifies the location of a file used by chef to tag an Appstream image_builder device. This tag is used to guard other resources so that chef can run as normal while the image builder is being prepared. After appstream_image builder is ran successfully, `cpe_appstream` will remove this file and perform an image capture.

A base install config might look like this
```
node.default['install'] = true
node.default['cpe_appstream']['image_builder_tag'] = ::File.join(
  node['cpe_uber_utils']['dirs']['cpe']['tags'],
  '.image_builder',
)
node.default['cpe_appstream']['applications'] = [
  {
    'name' => 'chrome',
    'display_name' => 'Google Chrome',
    'path' => 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'key' => nil,
  },
  {
    'name' => 'notepad',
    'display_name' => 'Notepad',
    'path' => 'C:\\Windows\\system32\\notepad.exe',
    'key' => nil,
  },
]
date = Time.now.strftime('%m_%d_%Y')
node.default['cpe_appstream']['image'] = {
  'name' => "CPE_Appstream_#{date}",
  'description' => 'Image Created Automatically using Chef Client',
  'display_name' => "CPE_Appstream_#{date}",
  'tags' => {
    'Owner' => 'cpe',
  },
}
```

