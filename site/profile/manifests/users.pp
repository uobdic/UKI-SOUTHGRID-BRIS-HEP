# puppet class to create local users
class profile::users {
  $groups     = lookup('profile::users::groups', Hash, 'deep', {})
  $users      = lookup('profile::users::users', Hash, 'deep', {})

  # symlink to the correct location (/home -> /users)
  file { '/home':
    ensure => link,
    target => '/users',
  }

  if empty($groups) {
    notice('No profile::users::groups specified')
  }

  if empty($users) {
    notice('No profile::users::users specified')
  }
  $node_info = lookup('site::node_info', Hash)

  if ($node_info['role'] == 'hdfs_namenode' or $::fqdn == 'sts.dice.priv' or $fqdn == 'sc01.dice.priv') {
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

  unless 'soolin' in $::fqdn or 'lcgce' in $::fqdn {
    create_resources('group', $groups, $defaults)
    create_resources('accounts::user', $users, $acc_defaults)
  }
  if $::fqdn == 'sts.dice.priv' {
    $users.each |$key, $value| {
      unless $value['ensure'] == 'absent' {
        file { ["/exports/users/${key}", "/exports/software/${key}", "/exports/scratch/${key}"]:
          ensure => directory,
          owner  => $key,
          group  => $acc_defaults['group'],
          mode   => '0700',
        }
      }
    }
  }
}
