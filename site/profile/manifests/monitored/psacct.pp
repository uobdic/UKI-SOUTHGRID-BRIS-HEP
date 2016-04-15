class profile::monitored::psacct {
  package { 'psacct': ensure => 'installed' }

  service { 'psacct':
    ensure => 'running',
    enable => true,
  }
}
