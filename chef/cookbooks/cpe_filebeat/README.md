cpe_filebeat Cookbook
========================
Installs filebeat, manages config and services.

This cookbook depends on the following cookbooks

* cpe_remote
* cpe_launchd

This cookbook is offered by Facebook in the [IT-CPE](https://github.com/facebook/IT-CPE) repository.

Attributes
----------
* node['cpe_filebeat']
* node['cpe_filebeat']['install']
* node['cpe_filebeat']['configure']
* node['cpe_filebeat']['config']
* node['cpe_filebeat']['certificate']
* node['cpe_filebeat']['unhealthy_limit']

Notes
-----
For details on configuration options, see the official documentation: https://www.elastic.co/guide/en/beats/filebeat/6.4/filebeat-reference-yml.html

If using a certificate in the filebeat config, the certificate may be added to this cookbook under cpe_filebeat/file/default/<certificate-name>.crt.
Set node['cpe_filebeat']['certificate'] to the name of the certificate in the cookbook and chef will install it in node['cpe_filebeat']['dir']

Chef will attempt to repair filebeat by reinstalling the service after the unhealthy limit (node['cpe_filebeat']['unhealthy_limit']) is reached.
If Chef runs every 30 minutes, an unhealhty_limit value of three will reinstall chef after 2 hours.

Usage
-----
Before using this cookbook to install filebeat, you will need to re-pack the zip/tar.gz files provided by Elastic. To do so, for each tar, do the following:

    tar xzf filebeat-6.4.2-darwin-x86_64.tar.gz
    cd filebeat-6.4.2-darwin-x86_64
    zip -r ../filebeat-6.4.2-darwin-x86_64.zip ./*

This will create a zip file where the contents are not in a subdirectory (as is the case with the files provided by Elastic).

For the Windows zip, you also need to repack it:

    unzip filebeat-6.4.2-windows-x86_64.zip
    cd filebeat-6.4.2-windows-x86_64
    zip -r ../filebeat-6.4.2-windows-x86_64_repack.zip ./*

Once they are repacked, they should be ready to use with this cookbook. cpe_remote_zip will ensure they are installed into `/opt/filebeat` or `c:\Program Files\filebeat`

By default, this cookbook will not install Filebeat or its preferences. You may enable management of each of these things individually (Pkg and Config ).

A config for shipping munki logs might look like this:

```ruby

node.default['cpe_filebeat']['install'] = true
node.default['cpe_filebeat']['configure'] = true
node.default['cpe_filebeat']['unhealthy_limit'] = 3
node.default['cpe_filebeat']['certificate'] = 'filebeat-prod.crt'
cert_path = ::File.join(node['cpe_filebeat']['dir'], node['cpe_filebeat']['certificate'])
node.default['cpe_filebeat']['config'] = {
  'output.logstash' =>
    {
      'hosts' => ['server.company.com:1234'],
      'ssl.certificate_authorities' => [cert_path],
    },
  'filebeat.inputs' => [
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
```

Note: The Filebeat config format is nesty and can be confusing, so be *absolutely* sure you have the format correct, otherwise the yaml will be wrong.


