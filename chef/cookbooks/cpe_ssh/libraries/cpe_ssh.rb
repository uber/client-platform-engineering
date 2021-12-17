#
# Cookbook:: cpe_ssh
# Libraries:: cpe_ssh
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

module CPE
  class SSH
    CHEF_MANAGED_TAG = '# Managed by Chef'
    OLD_CHEF_MANAGED_TAG = '# Chef Managed'
    BEGIN_HOST_TAG = '## Managed by Chef - Begin Host Config ##'
    END_HOST_TAG = '## Managed by Chef - End Host Config ##'

    def self.config_path
      '/etc/ssh/ssh_config'
    end

    def self.cpe_config_path
      '/etc/ssh/ssh_config_cpe'
    end

    def self.known_hosts_path
      '/etc/ssh/ssh_known_hosts'
    end

    def self.chef_managed?
      read_config.include?("#{CHEF_MANAGED_TAG}\n")
    end

    def self.chef_managed_config?
      # Make sure the include lines exists somewhere in the file
      lines = read_config
      return lines.each_cons(2).any? { |line1, line2| ssh_config_lines == [line1, line2] }
    end

    def self.read_config
      # filter old style configs with trailing OLD_CHEF_MANAGED_TAG
      lines = ::File.readlines(config_path)
      lines.reject! { |line| line =~ / #{OLD_CHEF_MANAGED_TAG}$/ }
      # Remove duplicate entries using OLD_CHEF_MANAGED_TAG
      tag_index = lines.index("#{OLD_CHEF_MANAGED_TAG}\n")
      if tag_index && tag_index >= 0
        lines.slice!(tag_index..tag_index + 1)
      end
      return lines
    end

    def self.ssh_config_lines
      [
        "#{CHEF_MANAGED_TAG}\n",
        "Include #{cpe_config_path}\n",
      ]
    end
  end
end
