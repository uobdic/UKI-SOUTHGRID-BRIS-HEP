# class for configuring the HTCondor submit node (scheduler)
# Parameters:
# @param periodic_remove_requirements [Hash]: Hash of requirements for periodic removal of jobs
class profile::htcondor::submit (
  Hash $periodic_remove_requirements = {},
) {
  file { '/etc/condor/config.d/00_accounting.conf':
    ensure => file,
    source => "puppet:///modules/${module_name}/etc/condor/00_accounting.conf",
    notify => Exec['/usr/sbin/condor_reconfig'],
  }

  file { '/etc/condor/config.d/12_resource_limits.conf':
    ensure  => file,
    content => template("${module_name}/etc/condor/12_resource_limits.conf.erb"),
    notify  => Exec['/usr/sbin/condor_reconfig'],
  }
}
