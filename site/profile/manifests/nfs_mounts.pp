# == Class: profile::nfs_mounts
class profile::nfs_mounts (
  Hash $mounts = {},
) {
  package { 'nfs-utils':
    ensure => present,
  }

  $dice_storage = lookup('dice::storage', Hash, 'deep', {})
  $default_server = $dice_storage['nfs']['server']
  $mounts.each |$mount_point, $settings| {
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
    $group = $settings['group'] ? {
      undef   => 'root',
      default => $settings['group'],
    }
    filepath { $mount_point:
      ensure      => directory,
      managedepth => 3,
      owner       => 'root',
      group       => $group,
      mode        => '0775',
    }
    mount { $mount_point:
      ensure  => mounted,
      device  => $device,
      fstype  => 'nfs',
      options => $options,
      atboot  => true,
      dump    => 0,
      pass    => 0,
      require => [File[$mount_point],Package['nfs-utils']],
    }
  }
}
