class role::htcondor_worker {
  $custom_machine_attributes = hiera_hash('htcondor::custom_machine_attributes',{})
  $custom_job_attributes     = hiera_hash('htcondor::custom_job_attributes', {})
  $start_jobs                = hiera('htcondor::start_jobs', true)

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

  unless $start_jobs {
    file {'/etc/condor/config.d/999_off.config':
      ensure  => 'present',
      content => 'START = !isUndefined(TARGET.MAGIC)',
      notify  => Exec['/usr/sbin/condor_reconfig'],
    }
  }

  class {'::singularity': }

  file {'/etc/condor/singularity_wrapper':
    ensure => present,
    mode   => '0755',
    source => "puppet:///modules/${module_name}/etc/condor/singularity_wrapper",
  }

  # SSSD for docker jobs
  if $::facts['operatingsystemmajrelease'] == '7'{
    file {'/etc/condor/config.d/60_docker.config':
      ensure => present,
      mode   => '0755',
      source => "puppet:///modules/${module_name}/etc/condor/config.d/60_docker.config",
    }

    file {'/etc/rsyslog.d/00_docker.conf':
      ensure => present,
      mode   => '0755',
      source => "puppet:///modules/${module_name}/etc/rsyslog.d/00_docker.conf",
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
