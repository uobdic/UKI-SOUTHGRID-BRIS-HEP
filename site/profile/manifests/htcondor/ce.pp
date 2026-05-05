class profile::htcondor::ce {
  # Ensure output dir exists (safe even if packages create it)
  file { '/var/lib/condor-ce/apel':
    ensure => directory,
    owner  => 'condor',
    group  => 'condor',
    mode   => '0755',
  }

  file { '/etc/condor/config.d/61-apel-machineattrs.conf':
    ensure => file,
    owner  => 'condor',
    group  => 'condor',
    mode   => '0644',
    source => 'puppet:///modules/profile/etc/condor/config.d/61-apel-machineattrs.conf',
    notify => Exec['condor_reconfig'],
  }

  exec { 'condor_reconfig':
    command     => 'condor_reconfig',
    refreshonly => true,
    path        => ['/usr/sbin','/usr/bin','/sbin','/bin'],
  }

  file { '/etc/condor-ce/config.d/99-local-apel.conf':
    ensure  => file,
    owner   => 'condor',
    group   => 'condor',
    mode    => '0644',
    source  => 'puppet:///modules/profile/etc/condor-ce/config.d/99-local-apel.conf',
    require => File['/var/lib/condor-ce/apel'],
    notify  => Exec['condor_ce_reconfig'],
  }

  exec { 'condor_ce_reconfig':
    command     => 'condor_ce_reconfig',
    refreshonly => true,
    path        => ['/usr/sbin','/usr/bin','/sbin','/bin'],
  }
}
