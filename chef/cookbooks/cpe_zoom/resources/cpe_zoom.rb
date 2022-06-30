#
# Cookbook:: cpe_zoom
# Resources:: cpe_zoom
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_zoom
provides :cpe_zoom, :os => 'darwin'

default_action :run

action_class do
  WINDOWS_GENERAL_SETTINGS_MAP = {
    'ZAutoSSOLogin' => 'ForceLoginWithSSO',
    'ZSSOHost' => 'ForceSSOURL',
    'ZAutoUpdate' => 'EnableClientAutoUpdate',
    'disableloginwithemail' => 'DisableLoginWithEmail',
    'nofacebook' => 'DisableFacebookLogin',
    'nogoogle' => 'DisableGoogleLogin',
  }.freeze

  WINDOWS_CHAT_SETTINGS_MAP = {
    'DisableLinkPreviewInChat' => 'DisableLinkPreviewInChat',
  }.freeze

  WINDOWS_IGNORABLE_SETTINGS_MAP = [
    'LastLoginType',
    'forcessourl', # ZSSOHost is already mapped to ForceSSOURL
  ].freeze

  def zoom_prefs
    node['cpe_zoom'].compact
  end

  def convert_to_registry_key(value)
    if value == true
      return { :data => 1, :type => :dword }
    elsif value == false
      return { :data => 0, :type => :dword }
    else
      return { :data => value.to_s, :type => :string }
    end
  end

  def configure_windows
    zoom_settings = {}
    zoom_prefs.each do |key, value|
      next if WINDOWS_IGNORABLE_SETTINGS_MAP.include?(key) # Skippable preferences on Windows

      preference = WINDOWS_CHAT_SETTINGS_MAP[key]
      if preference.nil? # If the preference isn't in WINDOWS_CHAT_SETTINGS_MAP, set General path.
        zoom_settings[WINDOWS_GENERAL_SETTINGS_MAP.fetch(key, key)] = {
           :path => 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Zoom\Zoom Meetings\General',
           :name => WINDOWS_GENERAL_SETTINGS_MAP.fetch(key, key),
         }.merge(convert_to_registry_key(value))
      else
        zoom_settings[preference] = {
          :path => 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Zoom\Zoom Meetings\chat',
          :name => key,
        }.merge(convert_to_registry_key(value))
      end
    end

    unless zoom_settings.empty?
      zoom_settings.each do |_name, reg_key|
        registry_key reg_key[:path] do
          values [{ :name => reg_key[:name], :type => reg_key[:type], :data => reg_key[:data] }]
          recursive true
          action :create
        end
      end
    end
  end

  def configure_macos
    prefix = node['cpe_profiles']['prefix']
    organization = node['organization'] || 'Uber'
    zoom_profile = {
      'PayloadIdentifier' => "#{prefix}.zoom",
      'PayloadRemovalDisallowed' => true,
      'PayloadScope' => 'System',
      'PayloadType' => 'Configuration',
      'PayloadUUID' => 'B1B0DEED-DC7C-4122-912F-A22F660DF53D',
      'PayloadOrganization' => organization,
      'PayloadVersion' => 1,
      'PayloadDisplayName' => 'Zoom',
      'PayloadContent' => [],
    }
    unless zoom_prefs.empty?
      zoom_profile['PayloadContent'].push(
        'PayloadType' => 'us.zoom.config',
        'PayloadVersion' => 1,
        'PayloadIdentifier' => "#{prefix}.zoom",
        'PayloadUUID' => 'B976C3E1-B59D-4060-80DA-13A42270D1E7',
        'PayloadEnabled' => true,
        'PayloadDisplayName' => 'Zoom',
      )
      zoom_prefs.each_key do |key|
        next if zoom_prefs[key].nil?
        zoom_profile['PayloadContent'][0][key] = zoom_prefs[key]
        # Double tap the preferences since Zoom didn't use profiles at one point. Requires Chef 14 or newer
        macos_userdefaults "Configure us.zoom.config - #{key}" do
          domain '/Library/Preferences/us.zoom.config'
          key key
          value zoom_prefs[key]
        end
      end
    end

    node.default['cpe_profiles']["#{prefix}.zoom"] = zoom_profile
  end
end

# Enforce Zoom Settings
action :run do
  return if zoom_prefs.empty?

  if macos?
    configure_macos
  elsif windows?
    configure_windows
  end
end
