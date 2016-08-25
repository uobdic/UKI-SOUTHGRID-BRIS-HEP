class profile::users {
  $groups       = hiera_hash('profile::users::groups', {
  }
  )
  $users        = hiera_hash('profile::users::users', {
  }
  )
  if empty($groups){
    notice('No profile::users::groups specified')
  }
  if empty($users){
    notice('No profile::users::users specified')
  }
  $role = hiera('site::node_info::role')

  if ($role == 'hdfs_namenode'){
    $shell        = hiera('profile::users::shell', '/sbin/nologin')
  }
  else {
    $shell        = hiera('profile::users::shell', '/bin/bash')
  }


  $defaults     = {
    'ensure' => present,
  }

  $acc_defaults = {
    'ensure'       => present,
    'shell'        => $shell,
    'password'     => '!!',
    'create_group' => false,
  }

  if $::fqdn != 'soolin.phy.bris.ac.uk' {
    create_resources('group', $groups, $defaults)
    create_resources('account', $users, $acc_defaults)
  }
}
