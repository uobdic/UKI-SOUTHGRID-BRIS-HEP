# manages the central logging behaviour of a machine (using rsyslog)

# 220817 struggle to get syntax so jt-37-00 is true = central syslog
# notify must be INSIDE the class
#notify {"Running with \$fqdn ${::fqdn} defined":}

class profile::monitored::central_log {
notify {"Running with \$fqdn ${::fqdn} defined":}
  $central_log = lookup('profile::monitored::central_log', Array, 'first', ['*.* @10.129.5.3:514'])
  $it_services_log = lookup('profile::monitored::it_services_log', Array, 'first', [])
# orig
#  $is_central_log = member($central_log, $::fqdn) or member($central_log,
#  $::ipaddress)
# added :514 then ::514 - both fail
#  $is_central_log = member($central_log, $::fqdn::514) or member($central_log,
#  $::ipaddress::514)
# Dr K says maybe syntax s/be
#  $is_central_log = member($central_log, "^$::fqdn") or member($central_log,
#  "^$::ipaddress")
# doesn't work either
#   $is_central_log = member($central_log, Regexp("^${::fqdn}")) or member($central_log,
#   Regexp("^${::ipaddress}"))

# try add :514
#  $is_central_log = member($central_log, "^$::fqdn::514") or member($central_log,
#  "^$::ipaddress::514")
# DrK suggests other syntax: THAT WORKS
   $is_central_log = member($central_log, "${::fqdn}:514") or member($central_log,
   "${::ipaddress}:514")


notify {"Running with \$is_central_log $is_central_log defined":}

  unless $is_central_log {
    file {'/etc/rsyslog.d':
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
              '/etc/rsyslog.d/99_it_services.conf'
          ]:
      ensure => 'absent',
    }

    file { '/etc/rsyslog.conf':
      ensure  => 'present',
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
