#
# Cookbook:: cpe_appstream
# Resources:: cpe_appstream
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2022-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_appstream
provides :cpe_appstream, :os => 'windows'

default_action :manage

action :manage do
  install if install? && valid_config?
end

action_class do # rubocop:disable Metrics/BlockLength
  def install?
    config['install']
  end

  def install
    remove_all_applications unless image_builder_added_applications.empty?
    image_builder_add_applications
    image_builder_capture_image
  end

  def remove_all_applications
    image_builder_added_applications.each do |app|
      node.image_builder_remove_application(app['Name'])
    end
  end

  def requested_application_names
    requested = []
    application_catalog.each do |app|
      requested << app['name'] if app.keys.include?('name')
    end
    requested
  end

  def image_builder_added_applications
    installed = []
    apps = node.image_builder_list_applications
    unless apps.nil? || apps.empty?
      apps['applications'].each do |app|
        installed << app['Name'] if app.keys.include?('Name')
      end
    end
    installed
  end

  def image_builder_add_applications
    # add all applications to Appstream config
    application_catalog.each do |app|
      cmd = "\'#{config['image_assistant_path']}\' add-application --name \'#{app['name']}\' "\
        "--absolute-app-path \'#{app['path']}\' --display-name \'#{app['display_name']}\'"
      powershell_script "Image Builder - Adding #{app['name']}" do
        code <<-PSSCRIPT
        $result = & #{cmd}
        $result = $result | convertfrom-json
        if ($result.status -eq 1) { Write-Output $result.message }
        exit $result.status
        PSSCRIPT
        not_if { image_builder_added_applications.include?(app['name']) }
        only_if { ::File.exists?(app['path']) }
      end
    end

    file 'C:/ProgramData/Amazon/Photon/Prewarm/PrewarmManifest.txt' do
      rights :full_control, 'S-1-1-0' # Everyone
      action :create_if_missing
    end
  end

  def image_builder_capture_image
    cmd = "\'#{config['image_assistant_path']}\' create-image --name \'#{image_config['name']}\'"
    cmd += " --description \'#{image_config['description']}\'" if image_config['description']
    cmd += " --display-name \'#{image_config['display_name']}\'" if image_config['display_name']
    cmd += " --tags #{image_config_tags}" if image_config_tags

    windows_task 'CaptureImage' do
      command "powershell.exe -noprofile -executionpolicy bypass -command \"Start-Sleep -Seconds 180; & #{cmd}\""
      frequency :none
      run_level :highest
    end

    file image_builder_tag do
      action :nothing
      notifies :run, 'windows_task[CaptureImage]', :delayed
    end

    powershell_script 'CaptureImage Test' do
      code <<-PSSCRIPT
      $result = & #{cmd} --dry-run
      $result = $result | convertfrom-json
      if ($result.status -eq 1) { Write-Output $result.message }
      exit $result.status
      PSSCRIPT
      action :run
      only_if { requested_application_names.sort == image_builder_added_applications.sort }
      notifies :delete, "file[#{image_builder_tag}]", :delayed
    end
  end

  def application_catalog
    config['applications'].to_a.each(&:compact!).reject(&:empty?)
  end

  def image_config
    config['image'].to_h.reject { |_k, v| v.nil? }
  end

  def image_config_tags
    tags = image_config['tags'].to_h.reject { |_k, v| v.nil? }
    tag_string = ''
    tags.each { |k, v| tag_string += "\'#{k}\' \'#{v}\' " }
    tag_string.chomp(' ')
  end

  def image_builder_tag
    config['image_builder_tag']
  end

  def config
    node['cpe_appstream']
  end

  def valid_config?
    image_config['name'] && image_builder_tag &&
      ::File.exists?(image_builder_tag) && ::File.exists?(config['image_assistant_path'])
  end
end
