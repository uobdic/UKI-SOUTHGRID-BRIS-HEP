# puppet class to create local users
class profile::users {
  $groups     = lookup('profile::users::groups', Hash, 'deep', {})
  $users      = lookup('profile::users::users', Hash, 'deep', {})

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
        }
      }
    }
    # symlink to the correct location (/home -> /users) for each user
    $users.each |$key, $value| {
      unless $value['ensure'] == 'absent' or "/home/${key}" == $value['home'] {
        file { "/home/${key}":
          ensure  => link,
          target  => $value['home'],
          require => User[$key],
        }
      }
      if $value['ensure'] == 'absent' and "/home/${key}" != $value['home'] {
        file { "/home/${key}":
          ensure => absent,
        }
      }
    }
  }
}
