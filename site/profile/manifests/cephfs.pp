# class for setting up Cephfs - mostly for clients and mounts
# @param keys - the keys to use for the cephfs client
# @param mounts - a hash of mounts to create; takes normal mount options
class profile::cephfs (
  Array[String] $keys = ['dice-reader'],
  Hash $mounts = {},
) {
  $ceph_release = 'centos-release-ceph-squid'
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

  $active_mounts = $mounts.filter |$mount_location, $options| {
    $options['ensure'] != 'absent'
  }

  $absent_mounts = $mounts.filter |$mount_location, $options| {
    $options['ensure'] == 'absent'
  }

  $active_mounts_normalised = $active_mounts.map |$mount_location, $options| {
    $mount_location => $options.filter |$key, $value| {
      $key != 'ensure'
    }
  }.reduce({}) |$result, $entry| {
    $result + $entry
  }

  # create the mounts
  if !$active_mounts_normalised.empty {
    # main mount point
    file { '/cephfs':
      ensure => directory,
    }
    $mount_locations = keys($active_mounts_normalised)
    file { $mount_locations:
      ensure => directory,
    }
    # create bind mount to main mount point
    $mount_locations.each |$mount_location| {
      $mount_name = $mount_location[1, -1]
      file { "/cephfs/${mount_name}":
        ensure  => directory,
      }
      mount { "/cephfs/${mount_name}":
        ensure  => 'mounted',
        device  => $mount_location,
        fstype  => 'none',
        options => 'bind,nobootwait,_netdev',
        require => [File["/cephfs/${mount_name}"], Mount[$mount_location]],
      }
    }
    if $facts['os']['release']['major'] == '9' {
      $defaults = {
        'require'  => [File['/etc/ceph/ceph.conf'], File[$mount_locations]],
        'fstype'   => 'ceph',
        'ensure'   => 'mounted',
        'options'  => 'noatime,_netdev',
      }
      create_resources('mount', $active_mounts_normalised, $defaults)
    } else {
      $active_mounts_normalised.map |$mount, $options| {
        # default options are of the form "dice-user@.dicefs=/dice"
        # we want to extract the client ID before the '@' sign
        $client_id = $options['device'].split('@')[0]
        $mount_point = $options['device'].split('=')[1]
        mount { $mount:
          ensure  => 'mounted',
          device  => 'none',
          fstype  => 'fuse.ceph',
          options => "ceph.id=${client_id},ceph.client_mountpoint=${mount_point},noatime,_netdev",
          require => [File['/etc/ceph/ceph.conf'], File[$mount]],
        }
      }
    }
  }

  # remove mounts that are marked as absent
  $absent_mounts.each |$mount_location, $options| {
    $mount_name = $mount_location[1, -1]
    $bind_location = "/cephfs/${mount_name}"

    mount { $bind_location:
      ensure => absent,
    }

    file { $bind_location:
      ensure  => absent,
      require => Mount[$bind_location],
    }

    mount { $mount_location:
      ensure  => absent,
      require => Mount[$bind_location],
    }

    file { $mount_location:
      ensure  => absent,
      require => Mount[$mount_location],
    }
  }
}
