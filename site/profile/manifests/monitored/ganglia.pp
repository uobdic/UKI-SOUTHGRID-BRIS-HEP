class profile::monitored::ganglia {
  $ganglia_servers       = hiera_array('profile::monitored::ganglia_servers', ['localhost'
    ])
  $ganglia_port          = hiera('profile::monitored::ganglia_port', 8650)
  $ganglia_cluster_name  = hiera('profile::monitored::ganglia_cluster_name', 'unknown'
  )
  $ganglia_use_multicast = hiera('profile::monitored::ganglia_use_multicast',
  false)

  if $ganglia_cluster_name == 'DICE' {
  $ganglia_packages      = ['ganglia-gmond-python', 'ganglia', 'ganglia-gmond']
  }
  else {
  $ganglia_packages      = ['ganglia-gmond']
  }

  package { $ganglia_packages:
    if $ganglia_cluster_name == 'DICE' {
       $version = '3.7.2-2'
    install_options => [{
        '--enablerepo' => 'epel'
      }
      ],
    }
    else {
       $version =  '3.0.7-1'
    install_options => [{
        '--enablerepo' => 'bristol'
      }
      ],
    }

    ensure          => $version,
  }

  if $ganglia_cluster_name == 'DICE' {
    $require_packages = [
      Package['ganglia-gmond-python'],
      Package['ganglia'],
      Package['ganglia-gmond']]
  } else{
    $require_packages = [
      Package['ganglia-gmond']]
  }

  file { '/etc/ganglia/gmond.conf':
    ensure  => 'present',
    content => template("${module_name}/gmond.conf.erb"),
    mode    => '0644',
    notify  => Service['gmond'],

  }

  file {'/etc/ganglia/conf.d/netstats.pyconf':
    ensure  => 'present',
    source  => "puppet:///modules/${module_name}/ganglia.netstats.pyconf.fixed",
    notify  => Service['gmond'],
  }

  service { 'gmond':
    ensure => 'running',
    enable => true,
  }
}
