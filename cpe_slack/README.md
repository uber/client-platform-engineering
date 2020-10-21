cpe_slack Cookbook
========================
Install a profile to manage slack settings


Attributes
----------
* node['cpe_slack']['preferences']
* node['cpe_slack']['signin_token']

Usage
-----
The profile will manage the `com.tinyspeck.slackmacgap` preference domain with the keys in `preferences`.

The profile's organization key defaults to `Uber` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload for the above keys in `node['cpe_slack']`.  The three provided have a sane default, which can be overridden in another recipe if desired.

This cookbook provides zero keys within the default attributes as there are many undocumented keys.

For a list of supported keys, please see this [Slack knowledge base article](https://slack.com/help/articles/360035635174-Deploy-Slack-for-macOS)

For example, you could tweak the above values
    # Disable the ability for Slack to auto-update
    node.default['cpe_slack']['SlackNoAutoUpdates'] = true

This cookbook can also set up slack to have a default signin domain, but populating a signon token. This only works if slack is already installed and `/Users/<console_user>/Library/Application Support/Slack` exists. Define `signin_token` to use. You can get your team ID for a signon token by following [these instructions](https://slack.com/intl/en-au/help/articles/360041725993-Share-a-default-sign-in-file-with-members).
