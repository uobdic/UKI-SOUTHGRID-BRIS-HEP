class profile::monitored::central_log {
  $central_log = hiera_array('profile::monitored::central_log', [])

  file { '/etc/rsyslog.d/central.conf':
    ensure  => 'present',
    content => template("${module_name}/central.conf.erb"),
    mode    => '0644',
    notify  => Service['rsyslog'],
  }

  service { 'rsyslog':
    ensure => 'running',
    enable => true,
  }
}
