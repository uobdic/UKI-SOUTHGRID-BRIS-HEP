class profile::htcondor_ce {
  $uid_domain    = lookup('htcondor::uid_domain', undef, undef, $::domain)
  $managers      = lookup('htcondor::managers', Array[String], 'unique', [])
  $argus_server  = $::site_info['argus_server']
  $argus_port    = $::site_info['argus_port']
  $supported_vos = $::site_info['supported_vos']
  $goc_site_name = $::site_info['gocdb_name']

  class { '::htcondor_ce':
    pool_collectors => $managers,
    uid_domain      => $uid_domain,
    argus_server    => $argus_server,
    argus_port      => $argus_port,
    supported_vos   => $supported_vos,
    goc_site_name   => $goc_site_name,
  }

  if $facts['networking']['fqdn'] == 'lcgce02.phy.bris.ac.uk' {
    file { '/etc/condor-ce/config.d/98-cms-storage-binds.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/profile/etc/condor-ce/config.d/98-cms-storage-binds.conf',
      require => Class['htcondor_ce'],
      notify  => Exec['condor_ce_reconfig'],
    }

    file { '/etc/condor-ce/config.d/99-scitokens.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/profile/etc/condor-ce/config.d/99-scitokens.conf',
      require => Class['htcondor_ce'],
      notify  => Exec['condor_ce_reconfig'],
    }
  }
}
