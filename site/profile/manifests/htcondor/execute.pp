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

  # Benchmark/accounting values from Hiera only.
  $site_info = lookup('site::site_info', Hash, 'first', {})
  $node_info = lookup('site::node_info', Hash, 'first', {})

  $baseline_block = $site_info.dig('benchmark_baseline') ? {
    undef   => {},
    default => $site_info.dig('benchmark_baseline'),
  }

  $baseline_type = $baseline_block.dig('type') ? {
    undef   => 'hepscore23',
    default => $baseline_block.dig('type'),
  }

  $baseline_per_core = $baseline_block.dig('per_core') ? {
    undef   => 20,
    default => $baseline_block.dig('per_core'),
  }

  $node_bench = $node_info.dig('benchmark', $baseline_type) ? {
    undef   => {},
    default => $node_info.dig('benchmark', $baseline_type),
  }

  # Missing node benchmark is allowed. Use neutral accounting scaling.
  $node_hepscore_per_core = $node_bench.dig('per_core') ? {
    undef   => $baseline_per_core,
    default => $node_bench.dig('per_core'),
  }

  $node_hepscore_total = $node_bench.dig('total') ? {
    undef   => 0,
    default => $node_bench.dig('total'),
  }

  # Scaling factor: neutral if baseline is missing/zero.
  $accounting_scale_factor = $baseline_per_core ? {
    0       => 1.0,
    default => ($node_hepscore_per_core / $baseline_per_core),
  }

  $apel_scaling          = sprintf('%.6f', $accounting_scale_factor)
  $hepscore_per_core_str = sprintf('%.3f', $node_hepscore_per_core)

  # Optional legacy specs
  $si2k_val = $node_info.dig('benchmark', 'si2k', 'per_core') ? {
    undef   => undef,
    default => $node_info.dig('benchmark', 'si2k', 'per_core'),
  }

  $hepspec_val = $node_info.dig('benchmark', 'hepspec06', 'per_core') ? {
    undef   => undef,
    default => $node_info.dig('benchmark', 'hepspec06', 'per_core'),
  }

  if $si2k_val {
    $apel_specs = "[HEPSCORE=${hepscore_per_core_str}; SI2K=${si2k_val}]"
  } else {
    $apel_specs = "[HEPSCORE=${hepscore_per_core_str}]"
  }

  # create the worker config file
  file { $worker_cfg:
    ensure  => file,
    owner   => 'condor',
    group   => 'condor',
    mode    => '0644',
    content => epp('profile/etc/condor/20_worker.conf.epp', {
        'accounting_scale_factor' => $accounting_scale_factor,
        'apel_scaling'            => $apel_scaling,
        'apel_specs'              => $apel_specs,
        'baseline_per_core'       => $baseline_per_core,
        'baseline_type'           => $baseline_type,
        'execute_dir'             => $execute_dir,
        'hepscore_per_core_str'   => $hepscore_per_core_str,
        'num_cpus'                => $num_cpus,
        'num_gpus'                => $num_gpus,
        'reserved_memory'         => $reserved_memory,
    }),
    notify  => Exec['/usr/sbin/condor_reconfig'],
  }
}
