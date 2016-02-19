# the base profile should include component modules that will be on all nodes
class profile::base {
  class { '::ntp': }

  $packages_to_install = hiera_array('packages_to_install', [])
  $packages_to_remove = hiera_array('packages_to_remove', [])

  package { $packages_to_install: ensure => 'present', }
  package { $packages_to_remove: ensure => 'absent', }
}
