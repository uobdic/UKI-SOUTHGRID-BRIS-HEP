class profile::htcondor_ce {
  $uid_domain    = hiera('htcondor::uid_domain', $::domain)
  $managers      = hiera('htcondor::managers', [])
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
}
