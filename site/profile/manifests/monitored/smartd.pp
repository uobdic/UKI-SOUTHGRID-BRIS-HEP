class profile::monitored::smartd {
  if !$::is_virtual {
    package { 'smartmontools': ensure => 'installed', }

    $custom_config_machines = ['soolin.dice.priv']

    if member($custom_config_machines, $::fqdn){
      file { '/etc/smartd.conf':
        ensure  => 'present',
        source => "puppet:///modules/${module_name}/smart.d/${fqdn}.conf",
        mode    => '0644',
        notify  => Service['smartd'],
        require => [Package['smartmontools'],]
      }
    }
    else {
      file { '/etc/smartd.conf':
        ensure  => 'present',
        content => template("${module_name}/smartd.conf.erb"),
        mode    => '0644',
        notify  => Service['smartd'],
        require => [Package['smartmontools'],]
      }
    }

    service { 'smartd':
      ensure  => 'running',
      enable  => true,
      require => [Package['smartmontools'],]
    }
  }
}
