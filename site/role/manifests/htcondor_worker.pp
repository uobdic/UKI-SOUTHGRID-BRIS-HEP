class role::htcondor_worker {
  $custom_machine_attributes = hiera_hash('htcondor::custom_machine_attributes',
  {
  }
  )
  $custom_job_attributes     = hiera_hash('htcondor::custom_job_attributes', {
  }
  )

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

}
