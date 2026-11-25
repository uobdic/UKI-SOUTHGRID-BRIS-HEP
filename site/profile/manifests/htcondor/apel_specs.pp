# Keep the execute node's benchmark attributes in the job history of a schedd.
#
# Execute nodes advertise ApelSpecs and ApelScaling (STARTD_ATTRS). With
# SYSTEM_JOB_MACHINE_ATTRS the schedd copies them into each matched job as
# MachineAttrApelSpecs0 / MachineAttrApelScaling0, where Auditor's HTCondor
# collector reads the benchmark score. Only jobs matched after this is applied
# carry them.
#
# Included by the CE settings and the submit profile; add it to the node data
# of any other schedd whose jobs Auditor collects. It has its own reconfig
# exec so it does not depend on the other HTCondor profiles.
class profile::htcondor::apel_specs {
  file { '/etc/condor/config.d/62-apel-specs.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/${module_name}/etc/condor/config.d/62-apel-specs.conf",
    notify => Exec['apel_specs_condor_reconfig'],
  }

  exec { 'apel_specs_condor_reconfig':
    command     => 'condor_reconfig',
    refreshonly => true,
    path        => ['/usr/sbin','/usr/bin','/sbin','/bin'],
  }
}
