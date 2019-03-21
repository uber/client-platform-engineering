cpe_uiagent Cookbook
=========================
Install a profile to manage the dock.

Requirements
------------
macOSs

Attributes
----------
* node['cpe_uiagent']
* node['cpe_uiagent']['CSUIDisable32BitWarnings']
* node['cpe_uiagent']['CSUIHasSafariBeenLaunched']
* node['cpe_uiagent']['CSUIRecommendSafariBackOffInterval']
* node['cpe_uiagent']['CSUIRecommendSafariNextNotificationDate']
* node['cpe_uiagent']['CSUILastOSVersionWhereSafariRecommendationWasMade']

Usage
-----
The profile will manage the `com.apple.coreservices.uiagent` preference domain.

The profile's organization key defaults to `Uber` unless `node['organization']` is
configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to `com.facebook.chef`

The profile delivers a payload of all keys in `node['cpe_uiagent']` that are non-nil values.  The provided defaults are nil, so that no profile is installed by default.

You can add any arbitrary keys to `node['cpe_uiagent']` to have them added to your profile.  As long as the values are not nil and create a valid profile, this cookbook will install and manage them.

```ruby
# Disable 32-Bit warnings on Mojave
node.default['cpe_uiagent']['CSUIDisable32BitWarnings'] = true

# Turn off the Safari notification banner
{
  'CSUIHasSafariBeenLaunched' => 1,
  'CSUIRecommendSafariBackOffInterval' => 'inf',
  'CSUIRecommendSafariNextNotificationDate' => '',
  'CSUILastOSVersionWhereSafariRecommendationWasMade' => '10.99',
}.each { |k, v| node.default['cpe_uiagent'][k] = v }
```
