class profile::users {
  $empty_hash = {
  }
  $groups     = hiera_hash('profile::users::groups', $empty_hash)
  $users      = hiera_hash('profile::users::users', $empty_hash)

  if empty($groups) {
    notice('No profile::users::groups specified')
  }

  if empty($users) {
    notice('No profile::users::users specified')
  }
  $node_info = hiera_hash('site::node_info')

  if ($node_info['role'] == 'hdfs_namenode') {
    $shell = hiera('profile::users::shell', '/sbin/nologin')
  } else {
    $shell = hiera('profile::users::shell', '/bin/bash')
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
}
