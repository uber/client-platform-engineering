#
# Cookbook:: cpe_nudge
# Recipes:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

return unless macos?

cpe_nudge_python_install 'Apply nudge-python install'
cpe_nudge_python_json 'Apply nudge-python json configuration'
cpe_nudge_python_launchagent 'Apply nudge-python agent configuration'

cpe_nudge_swift_install 'Apply nudge-swift install'
cpe_nudge_swift_json 'Apply nudge-swift json configuration'
cpe_nudge_swift_launchctl 'Apply nudge-swift launchctl configuration'
