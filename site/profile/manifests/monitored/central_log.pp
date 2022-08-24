# manages the central logging behaviour of a machine (using rsyslog)
class profile::monitored::central_log {
  $central_log = lookup('profile::monitored::central_log', Array, 'first', ['*.* @10.129.5.3:514'])
  $it_services_log = lookup('profile::monitored::it_services_log', Array, 'first', [])

  $is_central_log = member($central_log, "${facts['networking']['fqdn']}:514") or member($central_log, "${facts['networking']['ip']}:514")

  notify { 'rsyslog':
    message => "Running on \$fqdn ${facts['networking']['fqdn']} with \$is_central_log ${is_central_log} defined",
    level   => 'debug',
  }

  unless $is_central_log {
    file { '/etc/rsyslog.d':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    # remove obsolete configs
    file { [
        '/etc/rsyslog.d/central.conf',
        '/etc/rsyslog.d/00_docker.conf',
        '/etc/rsyslog.d/10_local.conf',
        '/etc/rsyslog.d/20_dice.conf',
        '/etc/rsyslog.d/99_it_services.conf',
      ]:
        ensure => 'absent',
    }

    file { '/etc/rsyslog.conf':
      ensure  => 'file',
      content => template("${module_name}/etc/rsyslog.conf.erb"),
      mode    => '0644',
      notify  => Service['rsyslog'],
    }
  }

  service { 'rsyslog':
    ensure => 'running',
    enable => true,
  }
}
