name 'cpe_crashplan'
maintainer 'Uber Technologies, Inc.'
maintainer_email 'noreply@uber.com'
license 'Apache'
description 'Installs/Configures cpe_crashplan'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

supports 'mac_os_x'

depends 'cpe_utils'
depends 'cpe_remote'
depends 'uber_helpers'
