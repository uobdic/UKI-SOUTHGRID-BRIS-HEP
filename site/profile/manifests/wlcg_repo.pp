# WLCG yum repository (linuxsoft.cern.ch/wlcg), installed through its repo RPM.
class profile::wlcg_repo {
  package { 'wlcg-repo':
    ensure   => present,
    provider => 'rpm',
    source   => 'https://linuxsoft.cern.ch/wlcg/el9/x86_64/wlcg-repo-1.0.0-1.el9.noarch.rpm',
  }
}
