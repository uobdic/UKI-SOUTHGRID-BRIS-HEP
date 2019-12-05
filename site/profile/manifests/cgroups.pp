# Configuration for cgroups
# see https://www.gridpp.ac.uk/wiki/Enable_Cgroups_in_HTCondor
class profile::cgroups {
  package { 'libcgroup': ensure => installed, }

  if $::osfamily == 'Redhat' and $::operatingsystemmajrelease == '6' {
    # in CentOS7 cgroups is automatically setup and all the systemd services are enabled
    service { 'cgconfig':
      ensure  => running,
      enable  => true,
      require => [Package['libcgroup']],
    }

    file { '/etc/cgconfig.d/00_cg_htcondor.conf':
      ensure  => present,
      source  => "puppet:///modules/${module_name}/00_cg_htcondor.conf",
      require => [Package['libcgroup']],
      notify  => Service['cgconfig'],
    }
  }

}
