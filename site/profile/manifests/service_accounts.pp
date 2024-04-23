# Class for managing service accounts
# @param groups [Hash] Hash of groups to create
# @param users [Hash] Hash of users to create
class profile::service_accounts (
  Hash $groups = {},
  Hash $users = {},
) {
  $group_defaults = {
    'ensure' => present,
  }
  $acc_defaults = {
    'ensure'       => present,
    'shell'        => '/sbin/nologin',
    'password'     => '!!',
    'create_group' => false,
    'managehome'   => false,
    'gid'          => '100',
    'group'        => 'users',
  }

  create_resources('group', $groups, $group_defaults)
  create_resources('accounts::user', $users, $acc_defaults)
  $users.each |$key, $value| {
    file { $value['home']:
      ensure  => directory,
      owner   => $key,
      group   => $value['group'],
      mode    => '0700',
      require => User[$key],
    }
  }
}
