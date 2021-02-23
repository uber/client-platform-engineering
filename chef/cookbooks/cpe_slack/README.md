cpe_slack Cookbook
========================
Install a profile to manage slack settings


Attributes
----------
* node['cpe_slack']

Usage
-----
The profile will manage the `com.tinyspeck.slackmacgap` preference domain.

The profile's organization key defaults to `Uber` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload for the above keys in `node['cpe_slack']`.  The three provided have a sane default, which can be overridden in another recipe if desired.

This cookbook provides zero keys within the default attributes as there are many undocumented keys.

For a list of supported keys, please see this [Slack knowledge base article](https://slack.com/help/articles/360035635174-Deploy-Slack-for-macOS)

For example, you could tweak the above values
    # Disable the ability for Slack to auto-update
    node.default['cpe_slack']['SlackNoAutoUpdates'] = true
