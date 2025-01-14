# Cookbook:: cpe_appstream
# Library:: appstream
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2022-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

class Chef
  class Node
    def image_assistant_path
      'C:/Program Files/Amazon/Photon/ConsoleImageBuilder/image-assistant.exe'
    end

    def image_builder_add_application(name, path, display_name)
      return unless windows?

      ps_cmd = "& \'#{image_assistant_path}\' add-application --name \"#{name}\""\
        " --absolute-app-path \"#{path}\" --display-name \"#{display_name}\""
      Chef::JSONCompat.parse(powershell_out(ps_cmd).stdout.to_s.chomp)
    end

    def image_builder_remove_application(name)
      return unless windows?

      ps_cmd = "& \'#{image_assistant_path}\' remove-application --name \"#{name}\""
      Chef::JSONCompat.parse(powershell_out(ps_cmd).stdout.to_s.chomp)
    end

    def image_builder_list_applications
      return unless windows?

      ps_cmd = "& \'#{image_assistant_path}\' list-applications"
      Chef::JSONCompat.parse(powershell_out(ps_cmd).stdout.to_s.chomp)
    end
  end
end
