#
# Cookbook Name:: cpe_ssh
# Libraries:: cpe_ssh
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

module CPE
  class SSH
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
      ::File.readlines(self.config_path).grep(/# Chef Managed/).any?
    end

    def self.chef_managed_config?
      ::File.readlines(self.config_path).grep(/#{self.ssh_config_line}/).any?
    end

    def self.read_config
      ::File.readlines(self.config_path)
    end

    def self.ssh_config_line
      'Include /etc/ssh/ssh_config_cpe # Chef Managed'
    end
  end
end
