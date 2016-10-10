# the base profile should include component modules that will be on all nodes
class profile::base {
  class { '::ntp': }

  $packages_to_install = hiera_array('packages_to_install', [])
  $packages_to_remove  = hiera_array('packages_to_remove', [])

  package { $packages_to_install: ensure => 'present', }

  package { $packages_to_remove: ensure => 'absent', }

  $_cron_min     = fqdn_rand(60, "${module_name}-min")
  $_cron_hour    = fqdn_rand(24, "${module_name}-hour")

  # run daily at a random minute in a random hour.
  $cron_schedule = "${_cron_min} ${_cron_hour} * * *"

  class { '::mlocate':
    cron_schedule    => $cron_schedule,
    extra_prunefs    => ['gpfs',],
    update_command   => '/etc/cron.daily/mlocate.cron',
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
      ],
  }
}
