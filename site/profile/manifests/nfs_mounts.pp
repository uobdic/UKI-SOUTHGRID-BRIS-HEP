# == Class: profile::nfs_mounts
class profile::nfs_mounts (
  Hash $nfs_mounts = {},
) {
  $default_server = lookup('dice::storage::nfs::server', String, 'deep')
  $nfs_mounts.each |$mount_point, $settings| {
    $server = $settings['server'] ? {
      undef   => $default_server,
      default => $settings['server'],
    }
    $read_options = $settings['read_only'] ? {
      false   => 'rw',
      default => 'ro',
    }
    $options = "${read_options},hard,intr,rsize=8192,wsize=8192,_netdev"
    $device = "${server}:${settings['path']}"
    file { $mount_point:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }
    mount { $mount_point:
      ensure  => mounted,
      device  => $device,
      fstype  => 'nfs',
      options => $options,
      atboot  => true,
      dump    => 0,
      pass    => 0,
      require => File[$mount_point],
    }
  }
}
