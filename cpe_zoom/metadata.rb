name 'cpe_zoom'
maintainer 'Uber Technologies, Inc.'
maintainer_email 'noreply@uber.com'
license 'Apache'
description 'Installs/Configures cpe_zoom'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
chef_version '>= 12.14' if respond_to?(:chef_version)

depends 'cpe_profiles'
depends 'cpe_utils'
