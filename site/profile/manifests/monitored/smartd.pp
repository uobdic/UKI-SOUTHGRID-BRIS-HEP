class profile::monitored::smartd {
  if !$::is_virtual {
    package { 'smartmontools': ensure => 'installed', }

    file { '/etc/smartd.conf':
      ensure  => 'present',
      content => template("${module_name}/smartd.conf.erb"),
      mode    => '0644',
      notify  => Service['smartd'],
      require => [Package['smartmontools'],]
    }

    service { 'smartd':
      ensure  => 'running',
      enable  => true,
      require => [Package['smartmontools'],]
    }
  }
}
