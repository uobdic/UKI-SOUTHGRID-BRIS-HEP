class profile::htcondor_ce {
  $uid_domain     = hiera('htcondor::uid_domain', $::domain)
  $managers       = hiera('htcondor::managers', [])
  $pool_collector = join($managers, ',')
  $condor_version = $::condor_version

  class { '::htcondor_ce':
    pool_collector => $pool_collector,
    uid_domain     => $uid_domain,
    lrms_version   => $condor_version,
  }

  class { '::htcondor_ce::bdii':
  }
}