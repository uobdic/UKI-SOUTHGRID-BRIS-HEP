class profile::cgroups {
  package { 'libcgroup': ensure => installed, }

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
