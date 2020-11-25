cpe_metricbeat Cookbook
========================
Installs metricbeat, manages config and services.

This cookbook depends on the following cookbooks

* cpe_remote
* cpe_launchd

These cookbooks are offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_metricbeat']
* node['cpe_metricbeat']['install']
* node['cpe_metricbeat']['configure']
* node['cpe_metricbeat']['config']

Notes
-----
For details on configuration options, see the official documentation: https://www.elastic.co/guide/en/beats/metricbeat/6.4/metricbeat-reference-yml.html

Usage
-----
Before using this cookbook to install metricbeat, you will need to re-pack the zip/tar.gz files provided by Elastic. To do so, for each tar, do the following:

    tar xzf metricbeat-6.4.2-darwin-x86_64.tar.gz
    cd metricbeat-6.4.2-darwin-x86_64
    zip -r ../metricbeat-6.4.2-darwin-x86_64.zip ./*

This will create a zip file where the contents are not in a subdirectory (as is the case with the files provided by Elastic).

For the Windows zip, you also need to repack it:

    unzip metricbeat-6.4.2-windows-x86_64.zip
    cd metricbeat-6.4.2-windows-x86_64
    zip -r ../metricbeat-6.4.2-windows-x86_64_repack.zip ./*

Once they are repacked, they should be ready to use with this cookbook. cpe_remote_zip will ensure they are installed into `/opt/metricbeat` or `c:\Program Files\metricbeat`

By default, this cookbook will not install metricbeat or its preferences. You may enable management of each of these things individually (Pkg and Config ).

A config for shipping munki logs might look like this:

    node.default['cpe_metricbeat']['install'] = true
    node.default['cpe_metricbeat']['configure'] = true
    node.default['cpe_metricbeat']['config'] = {
      'output.logstash' =>
        {
          'hosts' => ['YOUR_SERVER:YOUR_PORT'],
          # ToD this needs to be made cross platform
          'ssl.certificate_authorities' => [
            '/some/path/some_ca.crt',
          ],
        },
      'metricbeat.inputs' => [
        {
          'type' => 'log',
          'enabled' => true,
          'fields' => {
            'type' => 'my-munki-index',
          },
          'paths' => ['/Library/Managed Installs/Logs/*.log'],
          'encoding' => 'utf-8',
          'fields_under_root' => false,
        },

Note: The metricbeat config format is nesty and can be confusing, so be *absolutely* sure you have the format correct, otherwise the yaml will be wrong.
