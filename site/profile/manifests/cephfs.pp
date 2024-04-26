# class for setting up Cephfs - mostly for clients and mounts
# @param keys - the keys to use for the cephfs client
# @param mounts - a hash of mounts to create; takes normal mount options
class profile::cephfs (
  Array[String] $keys = ['dice-reader'],
  Hash $mounts = {},
) {
  $ceph_release = 'centos-release-ceph-reef'
  $ceph_mount_dependency = $facts['os']['release']['major'] ? {
    '7' => 'ceph-fuse',
    default => 'ceph-common',
  }
  if $facts['os']['release']['major'] == '7' {
    file { '/etc/yum.repos.d/ceph.repo':
      ensure => file,
      source => 'puppet:///dice_store/cephfs/ceph_el7.repo',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }
    $ceph_repo_dependency = File['/etc/yum.repos.d/ceph.repo']
  } else {
    package { $ceph_release: }
    $ceph_repo_dependency = Package[$ceph_release]
  }
  package { $ceph_mount_dependency:
    ensure          => latest,
    require         => $ceph_repo_dependency,
    install_options => ['--enablerepo', 'epel'],
  }

  # create the cephfs keys
  $keys.each |$key| {
    file { "/etc/ceph/ceph.client.${key}.keyring":
      ensure  => file,
      source  => "puppet:///dice_store/cephfs/ceph.client.${key}.keyring",
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      require => [Package[$ceph_mount_dependency]],
    }
  }

  file { '/etc/ceph/ceph.conf':
    ensure  => file,
    source  => 'puppet:///dice_store/cephfs/ceph.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [Package[$ceph_mount_dependency]],
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
    # create bind mount to main mount point
    $mount_locations.each |$mount_location| {
      file { "/cephfs/${mount_location}":
        ensure  => directory,
      }
      mount { "/cephfs/${mount_location}":
        ensure  => 'mounted',
        device  => $mount_location,
        fstype  => 'none',
        options => 'bind,nobootwait',
        require => [File["/cephfs/${mount_location}"], Mount[$mount_location]],
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
      $mounts.map |$mount, $options| {
        # default options are of the form "dice-user@.dicefs=/dice"
        # we want to extract the client ID before the '@' sign
        $client_id = $options['device'].split('@')[0]
        mount { $mount:
          ensure  => 'mounted',
          device  => 'none',
          fstype  => 'fuse.ceph',
          options => "ceph.id=${client_id},ceph.client_mountpoint=${options['device']},noatime,_netdev",
          require => [File['/etc/ceph/ceph.conf'], File[$mount]],
        }
      }
    }
  }
}
