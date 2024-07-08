# Class for installing HEP_OSlibs
class profile::heposlibs {
  String $repo_rpm = 'https://linuxsoft.cern.ch/wlcg/el9/x86_64/wlcg-repo-1.0.0-1.el9.noarch.rpm'
  String $package_name = 'HEP_OSlibs'

  package { 'wlcg-repo':
    ensure   => present,
    provider => 'rpm',
    source   => $repo_rpm,
  }

  package { $package_name:
    ensure  => present,
    require => Package['wlcg-repo'],
  }
}
