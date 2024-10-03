# manages the central logging behaviour of a machine (using rsyslog)
class profile::monitored::central_log {
  $central_log = lookup('profile::monitored::central_log', Array, 'first', ['*.* @10.129.5.3:514'])
  $it_services_log = lookup('profile::monitored::it_services_log', Array, 'first', [])

  $is_central_log = member($central_log, "${facts['networking']['fqdn']}:514") or member($central_log, "${facts['networking']['ip']}:514")

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
  }

  file { '/etc/rsyslog.conf':
    ensure  => 'file',
    content => template("${module_name}/etc/rsyslog.conf.erb"),
    mode    => '0644',
    notify  => Service['rsyslog'],
  }

  if $is_central_log {
    file { '/etc/rsyslog.d/listen.conf':
      ensure  => 'file',
      content => '$SystemLogSocketName /run/systemd/journal/syslog',
      notify  => Service['rsyslog'],
    }
    if $facts['os']['family'] == 'RedHat' and member(['8', '9'], $::facts['os']['release']['major']) {
      firewalld_port { 'syslog udp':
        ensure   => 'present',
        port     => 514,
        protocol => 'udp',
      }
      firewalld_port { 'syslog tcp':
        ensure   => 'present',
        port     => 514,
        protocol => 'tcp',
      }
    }
  }

  service { 'rsyslog':
    ensure => 'running',
    enable => true,
  }
}
