#
# Cookbook:: cpe_sal
# Libraries:: cpe_sal
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
  class Sal
    def self.existing_plugins
      Dir.entries(
        '/usr/local/sal/external_scripts',
      ).select { |f| f.include?('chef') }
    end

    def self.plugins_dir
      '/usr/local/sal/external_scripts'
    end

    def self.launchds
      [
        'com.salopensource.sal.random.runner',
        'com.salopensource.sal.runner',
      ]
    end
  end
end
