# Limit network namespace creation on Linux hosts.
# Disabling the mitigation restores the configured positive namespace limit.
class profile::security::network_namespaces (
  Boolean $enabled = true,
  Integer[1] $restored_limit = 127166,
) {
  if $facts['kernel'] == 'Linux' {
    exec { 'require user.max_net_namespaces sysctl':
      command => '/usr/bin/test -e /proc/sys/user/max_net_namespaces',
      unless  => '/usr/bin/test -e /proc/sys/user/max_net_namespaces',
    }

    if $enabled {
      file { '/etc/sysctl.d/92-max_net_namespaces.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "user.max_net_namespaces = 0\n",
        require => Exec['require user.max_net_namespaces sysctl'],
        notify  => Exec['apply network namespace limit'],
      }

      exec { 'apply network namespace limit':
        command     => '/usr/sbin/sysctl -p /etc/sysctl.d/92-max_net_namespaces.conf',
        refreshonly => true,
      }
    } else {
      file { '/etc/sysctl.d/92-max_net_namespaces.conf':
        ensure  => absent,
        require => Exec['require user.max_net_namespaces sysctl'],
      }

      exec { 'restore network namespace limit':
        command => "/usr/sbin/sysctl -w user.max_net_namespaces=${restored_limit}",
        unless  => "/bin/sh -c 'test \"$(/usr/sbin/sysctl -n user.max_net_namespaces)\" -eq ${restored_limit}'",
        require => File['/etc/sysctl.d/92-max_net_namespaces.conf'],
      }
    }
  }
}
