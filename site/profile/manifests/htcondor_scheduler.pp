# Profile for HTCondor submit node (scheduler)
class profile::htcondor_scheduler {
  $condor_user = lookup('htcondor::condor_user')
  $condor_group = lookup('htcondor::condor_group')
  file{'/etc/condor/config.d/99_bristol_extras.conf':
    source  => "puppet:///modules/${module_name}/99_htcondor_extras.conf",
    require => Package['condor'],
    owner   => $condor_user,
    group   => $condor_group,
    mode    => '0644',
    notify  => Exec['/usr/sbin/condor_reconfig'],
  }
}
