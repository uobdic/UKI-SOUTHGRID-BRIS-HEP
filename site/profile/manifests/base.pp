# the base profile should include component modules that will be on all nodes
class profile::base {
  if $::facts['os']['release']['major'] == '8' {
    # RHEL 8
    class { '::chrony':
      servers => $ntp::servers,
    }
  } else {
    # RHEL 7
    class { '::ntp': }
  }

  $packages_to_install = lookup('profile::default::packages_to_install', Array[String], 'unique', [])
  $packages_to_remove  = lookup('profile::default::packages_to_remove', Array[String], 'unique', [])

  # to be used for packages that need to be added to specific nodes/profiles/roles
  $extra_packages_to_install = lookup('profile::extra::packages_to_install', Array[String], 'deep', [])

  package { $packages_to_install: ensure => 'present', }
  package { $extra_packages_to_install: ensure => 'present', }

  package { $packages_to_remove: ensure => 'absent', }

  class { '::mlocate':
    update_command   => '/etc/cron.daily/mlocate.cron',
    extra_prunefs    => ['gpfs',],
    extra_prunepaths => [
      '/condor',
      '/dmlite',
      '/dpm',
      '/docker_registry',
      '/exports',
      '/gpfs',
      '/gpfs_phys',
      '/grid',
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
      '/hdfs',
      '/var/spool/arc',
      '/var/cache/cvmfs2',
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
