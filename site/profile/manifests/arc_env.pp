class profile::arc_env {
  file { [
    '/etc/arc',
    '/etc/arc/runtime',
    '/etc/arc/runtime/ENV',
    '/etc/arc/runtime/APPS',
    '/etc/arc/runtime/APPS/HEP']:
    ensure => 'directory',
  }

  file { '/etc/arc/runtime/APPS/HEP/ATLAS-SITE-LCG':
    ensure  => present,
    mode    => '0755',
    source  => "puppet:///modules/${module_name}/arc_env/ATLAS-SITE-LCG",
    require => File['/etc/arc/runtime/APPS/HEP'],
  }

  file { '/etc/arc/runtime/ENV/GLITE':
    ensure  => present,
    mode    => '0755',
    source  => "puppet:///modules/${module_name}/arc_env/GLITE",
    require => File['/etc/arc/runtime/ENV'],
  }

  file { '/etc/arc/runtime/ENV/PROXY':
    ensure  => present,
    mode    => '0755',
    source  => "puppet:///modules/${module_name}/arc_env/PROXY",
    require => File['/etc/arc/runtime/ENV'],
  }

}
