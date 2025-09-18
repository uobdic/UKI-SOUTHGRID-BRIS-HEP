# class for apptainer profile
class profile::apptainer {
  include apptainer
  # if on a condor execute node, also add config:
  $condor_role = lookup('profile::htcondor::role', 'none')
  if $condor_role == 'execute' {
    $bind_paths = lookup('apptainer::bind_paths')
    file { '/etc/condor/config.d/50-container.conf':
      ensure  => file,
      content => template('profile/etc/condor/50-container.conf.erb'),
    }
    file { '/etc/condor/container_wrapper':
      ensure => file,
      source => "puppet:///modules/${module_name}/etc/condor/container_wrapper",
      mode   => '0755',
    }
    file { '/etc/condor/get_bind_mounts':
      ensure => file,
      source => "puppet:///modules/${module_name}/etc/condor/get_bind_mounts",
      mode   => '0755',
    }
    # overwrite /usr/bin/apptainer with a wrapper script
    file { '/usr/bin/apptainer':
      ensure  => link,
      target  => '/etc/condor/container_wrapper',
      force   => true,
      require => File['/etc/condor/container_wrapper'],
    }
  }
}
