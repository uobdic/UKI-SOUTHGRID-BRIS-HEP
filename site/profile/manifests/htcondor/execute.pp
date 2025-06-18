# class to configre a HTC execute node (worker node)
# @param num_cpus [Integer] number of CPUs to allocate for HTCondor
# @param num_gpus [Integer] number of GPUs to allocate for HTCondor
# @param reserved_memory [Integer] amount of memory to reserve for the system - HTCondor will not use this memory
# @param execute_dir_base [String] base directory for the execute node - the execute node will create a subdirectory with its hostname
class profile::htcondor::execute (
  Integer $num_cpus = -1,
  Integer $num_gpus = 0,
  Integer $reserved_memory = 0,
  String $execute_dir_base = '/condor/scratch',
  Boolean $use_gpu = false,
  Boolean $start_jobs = true,
) {
  $execute_dir = "${execute_dir_base}/${facts['networking']['fqdn']}"
  $worker_cfg = '/etc/condor/config.d/20_worker.cfg'

  # create the worker config file
  file { $worker_cfg:
    ensure  => file,
    owner   => 'condor',
    group   => 'condor',
    mode    => '0644',
    content => template('profile/etc/condor/20_worker.conf.erb'),
    notify  => Exec['/usr/sbin/condor_reconfig'],
  }

  file { $execute_dir:
    ensure => directory,
    owner  => 'condor',
    group  => 'condor',
    mode   => '0755',
  }

  if $start_jobs {
    file { '/etc/condor/config.d/999_off.config':
      ensure => 'absent',
      notify => Exec['/usr/sbin/condor_reconfig'],
    }
  } else {
    file { '/etc/condor/config.d/999_off.config':
      ensure  => 'file',
      content => 'START = !isUndefined(TARGET.MAGIC)',
      notify  => Exec['/usr/sbin/condor_reconfig'],
    }
  }

  ## Environment setup
  ### grid certificate dir
  file { '/etc/grid-security':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  ### grid certificate directory is linked against CVMFS
  file { '/etc/grid-security/certificates':
    ensure  => link,
    target  => '/cvmfs/grid.cern.ch/etc/grid-security/certificates',
    require => File['/etc/grid-security'],
  }

  ### HEP OS libs are managed by profile::heposlibs
}
