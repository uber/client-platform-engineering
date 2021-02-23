cpe_zoom Cookbook
========================
Install a profile to manage diagnostic information submission settings.


Attributes
----------
* node['cpe_zoom']

Usage
-----
The profile will manage the `us.zoom.config` preference domain.

The profile's organization key defaults to `Uber` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload for the above keys in `node['cpe_zoom']`.  The three provided have a sane default, which can be overridden in another recipe if desired.

This cookbook provides zero keys within the default attributes as there are many undocumented keys.

For a list of supported keys, please see this [Zoom knowledge base article](https://support.zoom.us/hc/en-us/articles/115001799006-Mass-Deployment-with-Preconfigured-Settings-for-Mac)

For example, you could tweak the above values
    # Disable the ability for Zoom to turn on your webcam when joining a meeting.
    node.default['cpe_zoom']['ZDisableVideo'] = true
