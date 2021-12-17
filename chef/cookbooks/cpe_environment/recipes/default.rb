#
# Cookbook:: cpe_environment
# Recipe:: default
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

## The method used on linux *may* cause issues with bash updates due to
## apt not wanting to overwrite the config. See ITECPEP-165
## Do not scope to linux until this is test/resolved
return unless macos?

cpe_environment_zsh 'Manage Global ZSH Environment'
cpe_environment_bash 'Manage Global Bash Environment'
