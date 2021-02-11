name 'cpe_gorilla'
maintainer 'Uber Technologies, Inc.'
maintainer_email 'noreply@uber.com'
license 'Apache'
description 'This cookbook manages and installs gorilla.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

supports 'windows'

depends 'cpe_utils'
depends 'cpe_remote'
