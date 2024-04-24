# puppet class to create local users
class profile::users {
  $groups     = lookup('profile::users::groups', Hash, 'deep', {})
  $users      = lookup('profile::users::users', Hash, 'deep', {})
  $default_cephfs_quota = 1000000000000

  if empty($groups) {
    notice('No profile::users::groups specified')
  }

  if empty($users) {
    notice('No profile::users::users specified')
  }
  $node_info = lookup('site::node_info', Hash)
  $fqdn = $facts['networking']['fqdn']

  if ($node_info['role'] == 'hdfs_namenode' or $fqdn == 'sts.dice.priv') {
    $shell = lookup('profile::users::shell', undef, undef, '/sbin/nologin')
  } else {
    $shell = lookup('profile::users::shell', undef, undef, '/bin/bash')
  }

  $defaults     = {
    'ensure' => present,
  }

  $acc_defaults = {
    'ensure'       => present,
    'shell'        => $shell,
    'password'     => '!!',
    'create_group' => false,
    'managehome'   => false,
    'gid'          => '100',
    'group'        => 'users',
  }

  unless 'lcgce' in $fqdn {
    create_resources('group', $groups, $defaults)
    create_resources('accounts::user', $users, $acc_defaults)

    if $fqdn == 'sts.dice.priv' {
      $users.each |$key, $value| {
        unless $value['ensure'] == 'absent' {
          file { ["/exports/users/${key}", "/exports/software/${key}", "/exports/scratch/${key}", "/cephfs/dice/users/${key}"]:
            ensure => directory,
            owner  => $key,
            group  => $acc_defaults['group'],
            mode   => '0700',
          }
          # set quote for cephfs
          $quota = lookup("profile::users::${key}::cephfs_quota", Integer, 'deep', $default_cephfs_quota)
          exec { "set_cephfs_quota /cephfs/dice/users/${key}":
            command => "/usr/bin/setfattr -n ceph.quota.max_bytes -v ${$quota} /cephfs/dice/users/${key}",
            unless  => "/usr/bin/getfattr -n ceph.quota.max_bytes /cephfs/dice/users/${key}",
            require => File["/cephfs/dice/users/${key}"],
          }
        }
      }
    }
    # symlink to the correct location (/home -> /users) for each user
    unless $fqdn == 'sts.dice.priv' {
      $users.each |$key, $value| {
        unless $value['ensure'] == 'absent' or "/home/${key}" == $value['home'] {
          exec { "create_home_symlink_${key}":
            command => "/usr/bin/ln -s ${value['home']} /home/${key}",
            unless  => "/usr/bin/test -d /home/${key}",
          }
        }
        if $value['ensure'] == 'absent' and "/home/${key}" != $value['home'] {
          exec { "remove_home_symlink_${key}":
            command => "/usr/bin/rm -f /home/${key}",
            unless  => "/usr/bin/test -d /home/${key}",
          }
        }
      }
    }
  }
}
