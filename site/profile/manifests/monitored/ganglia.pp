class profile::monitored::ganglia {
  $ganglia_servers       = hiera_array('profile::monitored::ganglia_servers', ['localhost'
    ])
  $ganglia_port          = hiera('profile::monitored::ganglia_port', 8650)
  $ganglia_cluster_name  = hiera('profile::monitored::ganglia_cluster_name', 'unknown'
  )
  $ganglia_use_multicast = hiera('profile::monitored::ganglia_use_multicast',
  false)

  $ganglia_packages      = ['ganglia-gmond-python', 'ganglia', 'ganglia-gmond']

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
    notify  => Service['gmond'],
  }

  service { 'gmond':
    ensure => 'running',
    enable => true,
  }
}
