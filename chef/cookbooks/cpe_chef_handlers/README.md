cpe_chef_handlers cookbook
====================
Chef handlers allow shipping data to a local file store or remote endpoint about the status of a chef run. They run both when a chef run is successful as well as when chef fails to run successfully.

This cookbook handles the base config for adding chef handlers to a chef run via the `client.d` folder, which removes the need to put configs into `client.rb`.

Attributes
----------
```
node['cpe_chef_handlers']
node['cpe_chef_handlers']['configure'] # Bool
node['cpe_chef_handlers']['remove'] # Bool
node['cpe_chef_handlers']['config'] # Bool
```

Usage
----

handler_dir = '/path/to/chef/handlers'

# Make sure handler_dir exists.
directory handler_dir do
  action :create
end
# List all handlers here to install them
%w[
  my_handler.rb
].each do |chef_handler|
  handler_path = ::File.join(handler_dir, chef_handler)
  cookbook_file handler_path do
    source chef_handler
    user root_owner
    group node['root_group']
    mode '0644'
  end
end

# Configure cpe_chef_handlers to use handlers
node.default['cpe_chef_handlers']['configure'] = true
node.default['cpe_chef_handlers']['configs']['Runstats'] = {
  'file' => 'my_handler.rb',
  'parameters' => {
    'path' => '/var/chef/outputs',
  },
}
