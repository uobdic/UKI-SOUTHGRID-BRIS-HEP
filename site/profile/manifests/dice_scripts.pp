class profile::dice_scripts (
  Boolean $manage_scripts = false,
  Boolean $manage_cron    = false,
) {
  file { '/etc/dice':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # configs deployed everywhere
  file { '/etc/dice/nfs-storage-accounting.yaml':
    ensure  => file,
    source  => 'puppet:///modules/profile/etc/dice/nfs-storage-accounting.yaml',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/dice'],
  }

  file { '/etc/dice/cephfs-storage-accounting.yaml':
    ensure  => file,
    source  => 'puppet:///modules/profile/etc/dice/cephfs-storage-accounting.yaml',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/dice'],
  }

  if $manage_scripts {
    file { '/software/dice/scripts':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    file { '/software/dice/scripts/publish-nfs-storage-accounting.py':
      ensure  => file,
      source  => 'puppet:///modules/profile/etc/dice/publish-nfs-storage-accounting.py',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/software/dice/scripts'],
    }

    file { '/software/dice/scripts/publish-cephfs-storage-accounting.py':
      ensure  => file,
      source  => 'puppet:///modules/profile/etc/dice/publish-cephfs-storage-accounting.py',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/software/dice/scripts'],
    }
  }

  if $manage_cron {
    cron { 'publish-nfs-storage-accounting':
      ensure  => present,
      user    => 'root',
      hour    => 3,
      minute  => 17,
      command => '/software/dice/scripts/publish-nfs-storage-accounting.py -c /etc/dice/nfs-storage-accounting.yaml',
      require => [
        File['/etc/dice/nfs-storage-accounting.yaml'],
        File['/software/dice/scripts/publish-nfs-storage-accounting.py'],
      ],
    }

    cron { 'publish-cephfs-storage-accounting':
      ensure  => present,
      user    => 'root',
      hour    => 3,
      minute  => 21,
      command => '/software/dice/scripts/publish-cephfs-storage-accounting.py -c /etc/dice/cephfs-storage-accounting.yaml',
      require => [
        File['/etc/dice/cephfs-storage-accounting.yaml'],
        File['/software/dice/scripts/publish-cephfs-storage-accounting.py'],
      ],
    }
  }
}
