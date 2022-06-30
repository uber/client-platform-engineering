cpe_zoom Cookbook
========================
Manages Zoom Desktop Client configuration on macOS and Windows.


Attributes
----------
* node['cpe_zoom']

Usage
-----
On macOS, a profile will manage the `us.zoom.config` preference domain.

The profile's organization key defaults to `Uber`, unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload for the above keys in `node['cpe_zoom']`. The three provided have a sensible default, which can be overridden in another recipe if desired.

This cookbook doesn't provide any keys within the default attributes as there are many undocumented keys.

On Windows, take care not to deploy Zoom with MSI install arguments which conflict with the registry keys you set via this cookbook.

For a list of supported configuration keys, please see the Zoom knowledge base articles for [macOS](https://support.zoom.us/hc/en-us/articles/115001799006-Mass-Deployment-with-Preconfigured-Settings-for-Mac) and [Windows](https://support.zoom.us/hc/en-us/articles/201362163).

Example
-----
```ruby
    # Disable activating your webcam when joining meetings.
    node.default['cpe_zoom']['ZDisableVideo'] = true
```
