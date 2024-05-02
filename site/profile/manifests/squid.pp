# Configure Squid proxy server (https://twiki.cern.ch/twiki/bin/view/Frontier/InstallSquid)
class profile::squid {
  package { 'frontier-squid-release':
    ensure   => 'present',
    provider => 'yum',
    source   => 'http://frontier.cern.ch/dist/rpms/RPMS/noarch/frontier-release-1.2-1.noarch.rpm',
  }

  package { 'frontier-squid':
    ensure  => 'present',
    require => Package['frontier-squid-release'],
  }

  service { 'frontier-squid':
    ensure  => 'running',
    enable  => true,
    require => Package['frontier-squid'],
  }

  file { '/etc/squid/squid.conf':
    ensure  => 'file',
    source  => 'puppet:///modules/profile/etc/squid/squid.conf',
    require => Package['frontier-squid'],
    notify  => Service['frontier-squid'],
  }
}
