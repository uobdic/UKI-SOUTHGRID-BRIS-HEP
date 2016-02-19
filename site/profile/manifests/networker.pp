class profile::networker {
#  package {['lgtoclnt', 'lcgtoman']:
#    ensure => present,
#  }
#  
#  file {'/.nsr':
#    ensure => present,
#    source => 'puppet:///modules/${module_name}/nsr'
#  }
#
#  service {'networker':
#    enabled => true,
#    running => true,
#    require => [Package['lgtoman'], Package['lgtoclnt'], File['/.nsr']],
#  }
}