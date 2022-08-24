class profile::monitored::smartd {
  if !$fact::is_virtual {
    package { 'smartmontools': ensure => 'installed', }

    $custom_config_machines = ['soolin.dice.priv', 'dice-vm-37-00.acrc.bris.ac.uk', 'vm-37-02.acrc.bris.ac.uk', 'vm03.phy.bris.ac.uk']

    if member($custom_config_machines, $::fqdn) {
      notify { 'smartmontools': message => "smartmontools config for ${::fqdn}", }
      file { '/etc/smartmontools/smartd.conf':
        source  => "puppet:///modules/${module_name}/smart.d/${::fqdn}.conf",
        mode    => '0644',
        notify  => Service['smartd'],
        require => [Package['smartmontools'],],
      }
    }
    else {
      file { '/etc/smartmontools/smartd.conf':
        content => template("${module_name}/smartd.conf.erb"),
        mode    => '0644',
        notify  => Service['smartd'],
        require => [Package['smartmontools'],],
      }
    }

    service { 'smartd':
      ensure  => 'running',
      enable  => true,
      require => [Package['smartmontools'],],
    }
  }
}
