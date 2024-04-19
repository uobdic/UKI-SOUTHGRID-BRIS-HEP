# class for setting up Cephfs - mostly for clients and mounts
# @param keys - the keys to use for the cephfs client
# @param mounts - a hash of mounts to create; takes normal mount options
class profile::cephfs (
  Array[String] $keys = ['dice-reader'],
  Hash $mounts = {},
) {
  package { 'centos-release-ceph-reef': }
  package { 'ceph-common':
    ensure  => latest,
    require => [Package['centos-release-ceph-reef']],
  }

  # create the cephfs keys
  $keys.each |$key| {
    file { "/etc/ceph/ceph.client.${key}.keyring":
      ensure  => file,
      source  => "puppet:///dice_store/cephfs/ceph.client.${key}.keyring",
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      require => [Package['ceph-common']],
    }
  }

  file { '/etc/ceph/ceph.conf':
    ensure  => file,
    source  => 'puppet:///dice_store/cephfs/ceph.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [Package['ceph-common']],
  }

  # create the mounts
  if !$mounts.empty {
    # main mount point
    file { '/cephfs':
      ensure => directory,
    }
    $mount_locations = keys($mounts)
    file { $mount_locations:
      ensure => directory,
    }
    # create symlink to main mount point
    $mount_locations.each |$mount_location| {
      file { "/cephfs/${mount_location}":
        ensure  => link,
        target  => $mount_location,
        require => File[$mount_location],
      }
    }
    $defaults = {
      'require'  => [File['/etc/ceph/ceph.conf'], File[$mount_locations]],
      'fstype'   => 'ceph',
      'ensure'   => 'mounted',
      'options'  => 'noatime,_netdev',
    }
    create_resources('mount', $mounts, $defaults)
  }
}
