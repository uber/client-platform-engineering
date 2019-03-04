#
# Cookbook Name:: cpe_chefctl
# Libraries:: cpe_filebeat
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
  class Filebeat
    def self.getpath(basedir)
      ::File.join(basedir, 'filebeat')
    end
  end
end
