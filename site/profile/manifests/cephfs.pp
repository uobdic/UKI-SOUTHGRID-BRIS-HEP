# class for setting up Cephfs - mostly for clients and mounts
# @param keys - the keys to use for the cephfs client
# @param mounts - a hash of mounts to create; takes normal mount options
class profile::cephfs (
  Array[String] $keys = ['dice-reader'],
  Hash $mounts = {},
) {
  $ceph_release = $facts['os']['release']['major'] ? {
    '7' => 'https://download.ceph.com/rpm-octopus/el7/noarch/ceph-release-1-1.el7.noarch.rpm',
    default => 'centos-release-ceph-reef',
  }
  $ceph_mount_dependency = $facts['os']['release']['major'] ? {
    '7' => 'ceph-fuse',
    default => 'ceph-common',
  }

  package { $ceph_release: }
  package { $ceph_mount_dependency:
    ensure     => latest,
    require    => [Package[$ceph_release]],
    enablerepo => 'epel',
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
        require => [File[$mount_location], Mount[$mount_location]],
      }
    }
    if $facts['os']['release']['major'] == '9' {
      $defaults = {
        'require'  => [File['/etc/ceph/ceph.conf'], File[$mount_locations]],
        'fstype'   => 'ceph',
        'ensure'   => 'mounted',
        'options'  => 'noatime,_netdev',
      }
      create_resources('mount', $mounts, $defaults)
    } else {
      $ceph_fuse_mounts = $mounts.map |$mount, $options| {
        # default options are of the form "dice-user@.dicefs=/dice"
        # we want to extract the client ID before the '@' sign
        $client_id = $options['device'].split('@')[0]
        $ceph_fuse_mount = {
          $mount => {
            'ensure'  => 'mounted',
            'device'  => 'none',
            'fstype'  => 'ceph',
            'options' => "ceph.id=${client_id},ceph.client_mountpoint=${mount},noatime,_netdev",
            'require' => [File['/etc/ceph/ceph.conf'], File[$mount]],
          },
        }
        $ceph_fuse_mount
      }
      create_resources('mount', $ceph_fuse_mounts)
    }
  }
}
