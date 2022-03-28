# manages the central logging behaviour of a machine (using rsyslog)
class profile::monitored::central_log {
  $central_log = lookup('profile::monitored::central_log', Array, 'first', ['*.* @10.129.5.3:514'])
  $it_services_log = lookup('profile::monitored::it_services_log', Array, 'first', [])
  $is_central_log = member($central_log, $::fqdn) or member($central_log,
  $::ipaddress)

  unless $is_central_log {
    # include rsyslog::config
    # remove obsolete config
    file { '/etc/rsyslog.d/central.conf':
      ensure => 'absent',
    }

    # local logging
    file { '/etc/rsyslog.d/10_local.conf':
      ensure => 'present',
      source => "puppet:///modules/${module_name}/etc/rsyslog.d/10_local.conf",
      mode   => '0644',
      notify => Service['rsyslog'],
    }

    # remote DICE logging
    unless empty($central_log)
    {
      file { '/etc/rsyslog.d/20_dice.conf':
        ensure  => 'present',
        content => template("${module_name}/etc/rsyslog.d/20_dice.conf.erb"),
        mode    => '0644',
        notify  => Service['rsyslog'],
      }
    }

    # remote IT logging
    unless empty($it_services_log) {
      file { '/etc/rsyslog.d/99_it_services.conf':
        ensure  => 'present',
        content => template("${module_name}/etc/rsyslog.d/99_it_services.conf.erb"),
        mode    => '0644',
        notify  => Service['rsyslog'],
      }
    }

    file { '/etc/rsyslog.conf':
      ensure => 'present',
      source => "puppet:///modules/${module_name}/etc/rsyslog.conf",
      mode   => '0644',
      notify => Service['rsyslog'],
    }
  }

  service { 'rsyslog':
    ensure => 'running',
    enable => true,
  }
}
