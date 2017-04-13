# manages the central logging behaviour of a machine (using rsyslog)
class profile::monitored::central_log {
  $central_log = lookup('profile::monitored::central_log', Array, 'first', ['*.* @10.129.5.3:514'])

  $is_central_log = member($central_log, $::fqdn) or member($central_log,
  $::ipaddress)

  unless $is_central_log {
    file { '/etc/rsyslog.d/central.conf':
      ensure  => 'present',
      content => template("${module_name}/central.conf.erb"),
      mode    => '0644',
      notify  => Service['rsyslog'],
    }

    file { '/etc/rsyslog.conf':
      ensure => 'present',
      source => "puppet:///modules/${module_name}/rsyslog.conf",
      mode   => '0644',
      notify => Service['rsyslog'],
    }
  }

  service { 'rsyslog':
    ensure => 'running',
    enable => true,
  }
}
