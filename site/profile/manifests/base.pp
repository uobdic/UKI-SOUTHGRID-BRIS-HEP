# the base profile should include component modules that will be on all nodes
class profile::base {
  class { '::ntp': }

  $packages_to_install = lookup('packages_to_install', Array[String], 'unique', [])
  $packages_to_remove  = lookup('packages_to_remove', Array[String], 'unique', [])

  package { $packages_to_install: ensure => 'present', }

  package { $packages_to_remove: ensure => 'absent', }

  class { '::mlocate':
    update_command   => '/etc/cron.daily/mlocate.cron',
    extra_prunefs    => ['gpfs',],
    extra_prunepaths => [
      '/exports',
      '/hdfs',
      '/var/spool/arc',
      '/gpfs',
      '/gpfs_phys',
      '/var/cache/cvmfs2',
      '/condor',
      '/h1',
      '/h2',
      '/h3',
      '/h4',
      '/h5',
      '/h6',
      '/h7',
      '/h8',
      '/h9',
      '/h10',
      '/h11',
      '/h12',
      '/grid',
      ],
  }
  # cleanup after bad mlocate module (it is OK now, but first time was bad)
  file{['/etc/cron.d/mlocate.cron', '/usr/local/bin/mlocate.cron']:
    ensure => 'absent',
  }

  if !empty($facts['node_info']) {
    if $facts['node_info']['managed_network'] {
      include network::global
      include network::hiera
    }
  }
}
