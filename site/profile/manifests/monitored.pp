class profile::monitored {
  $ganglia_servers          = hiera_array('profile::monitored::ganglia_servers', ['localhost'])
  $ganglia_port             = hiera('profile::monitored::ganglia_port', 8650)
  $ganglia_cluster_name     = hiera('profile::monitored::ganglia_cluster_name', 'unknown')

  $ganglia_packages = ['ganglia-gmond-python', 'ganglia', 'ganglia-gmond']

  package { $ganglia_packages:
    ensure          => 'installed',
    install_options => [{
        '--enablerepo' => 'epel'
      }
      ],
  }

  file { '/etc/ganglia/gmond.conf':
    ensure  => 'present',
    content => template("${module_name}/gmond.conf.erb"),
    mode    => '0644',
    require => [
      Package['ganglia-gmond-python'],
      Package['ganglia'],
      Package['ganglia-gmond']],
  }

  # smartd
  if !$::is_virtual {
    file { '/etc/smartd.conf':
      ensure  => 'present',
      content => template("${module_name}/smartd.conf.erb"),
      mode    => '0644',
    }
  }

  # central log
  file { '/etc/rsyslog.d/central.conf':
      ensure  => 'present',
      content => template("${module_name}/central.conf.erb"),
      mode    => '0644',
    }
}
