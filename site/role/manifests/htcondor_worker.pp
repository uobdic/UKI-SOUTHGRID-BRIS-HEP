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
    mode => '0755',
    ensure => present,
    source => "puppet:///modules/${module_name}/etc/condor/singularity_wrapper",
  }

}
