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

  if ($node_info['role'] == 'hdfs_namenode') {
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
}
