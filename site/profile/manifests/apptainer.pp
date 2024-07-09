# class for apptainer profile
class profile::apptainer {
  include apptainer
  # if on a condor execute node, also add config:
  $condor_role = lookup('profile::htcondor::role')
  if $condor_role == 'execute' {
    $bind_paths = lookup('apptainer::bind_paths')
    file {'/etc/condor/config.d/50-container.conf':
    ensure  => file,
    content => template('profile/etc/condor/50-container.conf.erb'),
  }
  file {'/etc/condor/container_wrapper':
    ensure => file,
    source => "puppet:///modules/${module_name}/etc/condor/container_wrapper",
    mode   => '0755',
  }
  }

}
