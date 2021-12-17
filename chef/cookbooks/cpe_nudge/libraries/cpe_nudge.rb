#
# Cookbook:: cpe_nudge
# Library:: cpe_nudge
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright:: (c) 2019-present, Uber Technologies, Inc.
# All rights reserved.
#
# This source code is licensed under the Apache 2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

class Chef
  class Node
    # This portion is taken from cpe_launchd. Since we use cpe_launchd to
    # create our launch agent, the label specified in the attributes will not
    # match the actual label/path that's created. Doing this will result in
    # the right file being targeted.
    def nudge_launchctl_label(nudge_type, identifier_type)
      label = node['cpe_nudge']["nudge-#{nudge_type}"][identifier_type]
      if label.start_with?('com')
        name = label.split('.')
        name.delete('com')
        label = name.join('.')
        label = "#{node['cpe_launchd']['prefix']}.#{label}"
      end
      label
    end

    def nudge_launchctl_path(nudge_type, identifier_type)
      label = nudge_launchctl_label(nudge_type, identifier_type)
      if identifier_type == 'launchagent_identifier'
        ::File.join('/Library/LaunchAgents', "#{label}.plist")
      else
        ::File.join('/Library/LaunchDaemons', "#{label}.plist")
      end
    end
  end
end
