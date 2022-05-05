class role::htcondor_worker {
  $custom_machine_attributes = lookup('htcondor::custom_machine_attributes', Hash, deep, {})
  $custom_job_attributes     = lookup('htcondor::custom_job_attributes', Hash, deep, {})
  $start_jobs                = lookup('htcondor::start_jobs', undef, undef, true)


  $site_machine_attributes   = {
    'CLUSTER'                 => $::node_info['cluster'],
    'HEPSPEC06'               => $::node_info['hepspec06'],
    'ACCOUNTING_SCALE_FACTOR' => $::node_info['accounting_scale_factor'],
  }

  $site_job_attributes       = {
    'HEPSPEC06'               => $::node_info['hepspec06'],
    'ACCOUNTING_SCALE_FACTOR' => $::node_info['accounting_scale_factor'],
  }

  $merged_machine_attributes = merge($custom_machine_attributes,
  $site_machine_attributes)

  $merged_job_attributes     = merge($custom_job_attributes,
  $site_job_attributes)

  class { '::htcondor':
    custom_machine_attributes => $merged_machine_attributes,
    custom_job_attributes     => $merged_job_attributes,
  }

  if $start_jobs {
    file {'/etc/condor/config.d/999_off.config':
      ensure => 'absent',
      notify => Exec['/usr/sbin/condor_reconfig'],
    }
  } else {
    file {'/etc/condor/config.d/999_off.config':
      ensure  => 'present',
      content => 'START = !isUndefined(TARGET.MAGIC)',
      notify  => Exec['/usr/sbin/condor_reconfig'],
    }
  }

  file {'/etc/condor/config.d/888_ipv6_off.config':
      ensure  => 'present',
      content => 'ENABLE_IPV6 = FALSE',
      notify  => Exec['/usr/sbin/condor_reconfig'],
  }

  class {'::singularity': }

  file { '/etc/singularity':
    ensure => 'directory',
  }

  file { '/usr/bin/singularity':
    ensure => 'absent',
  }


  file {'/etc/condor/singularity_wrapper':
    ensure => present,
    mode   => '0755',
    source => "puppet:///modules/${module_name}/etc/condor/singularity_wrapper",
  }

  # file {'/etc/condor/healthcheck_workernode':
  #   ensure => present,
  #   mode   => '0755',
  #   source => "puppet:///modules/${module_name}/etc/condor/healthcheck_workernode",
  # }

  file {'/etc/profile.d/00_grid.sh':
    ensure => present,
    source => "puppet:///modules/${module_name}/etc/profile.d/00_grid.sh",
  }

  # SSSD for docker jobs
  if $::facts['operatingsystemmajrelease'] == '7'{
    file {'/etc/condor/config.d/60_docker.config':
      ensure => present,
      mode   => '0644',
      source => "puppet:///modules/${module_name}/etc/condor/config.d/60_docker.config",
    }

    package{'sssd':
      ensure => present,
    }

    service{'sssd':
      ensure  => running,
      enable  => true,
      require => Package['sssd'],
    }
  }

}
