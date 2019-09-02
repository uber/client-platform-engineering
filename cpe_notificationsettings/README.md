cpe_notificationsettings Cookbook
=========================
Install a profile to manage Apple notification settings

This cookbook depends on the following cookbooks

* cpe_profiles
* cpe_utils

These cookbooks are offered by Facebook in the
[IT-CPE](https://github.com/facebook/IT-CPE) repository.

Requirements
------------
macOS 10.15+

See Apple's
[Developer documentation](https://developer.apple.com/documentation/devicemanagement/notifications/notificationsettingsitem?changes=latest_minor)
for more information on this profile payload.

Attributes
----------
* node['cpe_notificationsettings']

Usage
-----
The profile will manage the `com.apple.notificationsettings` preference domain.

The profile's organization key defaults to `Uber` unless `node['organization']`
is configured in your company's custom init recipe. The profile will also use
whichever prefix is set in node['cpe_profiles']['prefix'], which defaults to
`com.facebook.chef`

You can add any arbitrary keys to `node['cpe_notificationsettings']` to have
them added to your profile.  As long as the values are not nil and create a
valid profile, this cookbook will install and manage them.

```
# Allow Munki and Yo to display notification center settings
[
  # Munki
  {
    'AlertType' => 2,
    'BadgesEnabled' => true,
    'BundleIdentifier' => 'com.googlecode.munki.ManagedSoftwareCenter',
    'CriticalAlertEnabled' => false,
    'NotificationsEnabled' => true,
    'ShowInNotificationCenter' => true,
    'ShowInLockScreen' => true,
    'SoundsEnabled' => true,
  },
  # Yo
  {
    'AlertType' => 1,
    'BadgesEnabled' => true,
    'BundleIdentifier' => 'com.github.sheagcraig.yo',
    'CriticalAlertEnabled' => false,
    'NotificationsEnabled' => true,
    'ShowInNotificationCenter' => true,
    'ShowInLockScreen' => true,
    'SoundsEnabled' => true,
  },
].each do |item|
  node.default['cpe_notificationsettings']['NotificationSettings'] << item
end
```
