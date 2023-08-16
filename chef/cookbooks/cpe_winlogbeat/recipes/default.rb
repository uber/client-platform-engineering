#
# Cookbook:: cpe_winlogbeat
# Recipes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2022-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

return unless windows?

cpe_winlogbeat 'Install and Configure winlogbeat'
