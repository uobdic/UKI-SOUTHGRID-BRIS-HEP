class profile::monitored::smartd {
  if !$::is_virtual {
    file { '/etc/smartd.conf':
      ensure  => 'present',
      content => template("${module_name}/smartd.conf.erb"),
      mode    => '0644',
      notify  => Service['smartd'],
    }

    service { 'smartd':
      ensure => 'running',
      enable => true,
    }
  }
}
