#
# Cookbook Name:: cpe_osquery
# Recipes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

return unless node.macos? || node.windows? || node.debian_family?

cpe_osquery 'Install and Configure osquery'
