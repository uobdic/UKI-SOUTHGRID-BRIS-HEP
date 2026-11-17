class profile::htcondor::ce_settings {
  file { '/etc/condor-ce/config.d/98-cms-storage-binds.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/etc/condor-ce/config.d/98-cms-storage-binds.conf',
    notify  => Exec['condor_ce_reconfig'],
  }

  file { '/etc/condor-ce/config.d/99-scitokens.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/etc/condor-ce/config.d/99-scitokens.conf',
    notify  => Exec['condor_ce_reconfig'],
  }

  exec { 'condor_ce_reconfig':
    command     => 'condor_ce_reconfig',
    refreshonly => true,
    path        => ['/usr/sbin','/usr/bin','/sbin','/bin'],
  }
}
