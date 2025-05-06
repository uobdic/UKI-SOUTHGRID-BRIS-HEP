# Profile for poolaccounts
class profile::users::poolaccounts (
  Hash $groups = {},
  Hash $users  = {},
) {
  $defaults     = {
    'ensure' => present,
    'tag'    => 'poolaccounts::groups',
  }
  $acc_defaults = {
    'ensure'        => present,
    'shell'         => '/sbin/nologin',
    'password'      => '!!',
    'create_group'  => false,
    'managehome'    => true,
    'gid'           => '100',
    'group'         => 'users',
    'tag'           => 'poolaccounts::users',
    'bashrc_source' => 'puppet:///modules/accounts/shell/bashrc',
  }
  create_resources('group', $groups, $defaults)
  create_resources('accounts::user', $users, $acc_defaults)
}
