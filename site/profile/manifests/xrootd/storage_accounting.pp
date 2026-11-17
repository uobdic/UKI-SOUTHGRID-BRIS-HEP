class profile::xrootd::storage_accounting (
  String $output = '/xrootd/public/storagecapacity.json',
) {
  package { [
      'python3-pyyaml',
      'attr',
    ]:
      ensure => installed,
  }

  file { '/etc/xrootd/publish-xrootd-storage-accounting':
    ensure => file,
    source => 'puppet:///modules/profile/etc/xrootd/publish-storage-accounting.py',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/xrootd/storage-accounting.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp(
      'profile/etc/xrootd/storage-accounting.yaml.epp',
      {
        output => $output,
      }
    ),
  }

  cron { 'publish-xrootd-storage-accounting':
    ensure  => present,
    user    => 'root',
    minute  => '17',
    hour    => '*',
    command => '/etc/xrootd/publish-xrootd-storage-accounting',
    require => [
      File['/etc/xrootd/publish-xrootd-storage-accounting'],
      File['/etc/xrootd/storage-accounting.yaml'],
    ],
  }
}
