#
class profile::monitored::ganglia {
  $ganglia_servers       = lookup('profile::monitored::ganglia_servers', Array[String], 'unique', ['localhost'])
  $ganglia_port          = lookup('profile::monitored::ganglia_port', undef, undef, 8650)
  $ganglia_cluster_name  = lookup('profile::monitored::ganglia_cluster_name', undef, undef, 'unknown')
  $ganglia_use_multicast = lookup('profile::monitored::ganglia_use_multicast', undef, undef, false)

  case $::facts['os']['release']['major'] {
    '7': {
      $ganglia_packages = ['ganglia-gmond-python', 'ganglia', 'ganglia-gmond']
    }
    /^(8|9)$/: {
      $ganglia_packages = ['python3-ganglia-gmond', 'ganglia', 'ganglia-gmond']
    }
    default: {
      fail('OS is not supported. Only RHEL (and derivatives) 7, 8 and 9 are')
    }

  }

  if $ganglia_cluster_name == 'unknown' {

  }
  elsif $ganglia_cluster_name == 'DICE' {
    $version = 'installed'
    package { $ganglia_packages:
      ensure          => $version,
      install_options => [{ '--enablerepo' => 'epel' } ],
    }
    file { '/etc/ganglia/gmond.conf':
      ensure  => 'present',
      content => template("${module_name}/gmond.conf.erb"),
      mode    => '0644',
      notify  => Service['gmond'],
    }
    file {'/etc/ganglia/conf.d/netstats.pyconf':
      ensure => 'present',
      source => "puppet:///modules/${module_name}/ganglia.netstats.pyconf.fixed",
      notify => Service['gmond'],
    }
    service { 'gmond':
      ensure => 'running',
      enable => true,
    }
  }
  else {
    $version =  '3.0.7-1'
    package { ['ganglia-gmond']:
      ensure          => $version,
      install_options => [{ '--enablerepo' => 'bristol' } ],
    }
    file {'/etc/gmond.conf':
      ensure => 'present',
      notify => Service['gmond'],
    }
    service { 'gmond':
      ensure => 'running',
      enable => true,
    }
  }
}
