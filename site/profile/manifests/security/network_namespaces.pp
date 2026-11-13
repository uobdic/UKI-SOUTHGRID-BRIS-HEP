# Limit network namespace creation on Linux hosts.
class profile::security::network_namespaces {
  if $facts['kernel'] == 'Linux' {
    exec { 'require user.max_net_namespaces sysctl':
      command => '/usr/bin/test -e /proc/sys/user/max_net_namespaces',
      unless  => '/usr/bin/test -e /proc/sys/user/max_net_namespaces',
    }

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
  }
}
