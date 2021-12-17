#
# Cookbook:: cpe_ulimit
# Resources:: cpe_ulimit
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#
unified_mode true

resource_name :cpe_ulimit
provides :cpe_ulimit, :os => 'darwin'
default_action :manage

action :manage do
  manage if node['cpe_ulimit']['manage']
end

action_class do
  def manage
    max_files
    max_processes
    sysctl_max_files
  end

  def max_files
    # Configure launchd item
    soft_limit = node['cpe_ulimit']['maxfiles_soft_limit']
    hard_limit = node['cpe_ulimit']['maxfiles_hard_limit']
    if soft_limit.nil? || hard_limit.nil?
      Chef::Log.warn('cpe_ulimit maxfiles soft/hard limits not configured. ' \
        'Skipping install')
    else
      # ServiceIPC is not available in the launchd resource, so cpe_launchd nor
      # launchd resource can natively accept the parameters. We must use the
      # "plist_hash" feature of the launchd resource.
      max_files_hash = {
        'Label' => node['cpe_launchd']['prefix'] + '.maxfiles',
        'ProgramArguments' => [
          '/bin/launchctl',
          'limit',
          'maxfiles',
          soft_limit,
          hard_limit,
        ],
        'RunAtLoad' => true,
        'ServiceIPC' => false,
      }
      node.default['cpe_launchd']['maxfiles'] = {
        'plist_hash' => max_files_hash,
        'type' => 'daemon',
      }
    end
  end

  def max_processes
    # Configure launchd item
    soft_limit = node['cpe_ulimit']['maxproc_soft_limit']
    hard_limit = node['cpe_ulimit']['maxproc_hard_limit']
    if soft_limit.nil? || hard_limit.nil?
      Chef::Log.warn('cpe_ulimit maxproc soft/hard limits not configured. ' \
        'Skipping install')
    else
      # ServiceIPC is not available in the launchd resource, so cpe_launchd nor
      # launchd resource can natively accept the parameters. We must use the
      # "plist_hash" feature of the launchd resource.
      max_proc_hash = {
        'Label' => node['cpe_launchd']['prefix'] + '.maxproc',
        'ProgramArguments' => [
          '/bin/launchctl',
          'limit',
          'maxproc',
          soft_limit,
          hard_limit,
        ],
        'RunAtLoad' => true,
        'ServiceIPC' => false,
      }
      node.default['cpe_launchd']['maxproc'] = {
        'plist_hash' => max_proc_hash,
        'type' => 'daemon',
      }
    end
  end

  def sysctl_max_files
    # Configure launchd item
    sysctl_maxfiles_limit = node['cpe_ulimit']['sysctl_maxfiles']
    if sysctl_maxfiles_limit.nil?
      Chef::Log.warn('cpe_ulimit sysctl_maxfiles limit not configured. ' \
        'Skipping install')
    else
      node.default['cpe_launchd']['sysctl_maxfiles'] =
        {
          'program_arguments' => [
            '/usr/sbin/sysctl',
            '-w',
            'kern.maxfiles=' + sysctl_maxfiles_limit,
          ],
          'run_at_load' => true,
          'type' => 'daemon',
        }
    end
  end
end
