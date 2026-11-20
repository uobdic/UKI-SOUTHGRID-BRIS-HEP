# Class for installing HEP_OSlibs
class profile::heposlibs {
  $package_name = 'HEP_OSlibs'

  include profile::wlcg_repo

  package { $package_name:
    ensure  => present,
    require => Package['wlcg-repo'],
  }
}
