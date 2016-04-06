class profile::users {
  $groups   = hiera_hash('profile::users::groups', {
  }
  )
  $users    = hiera_hash('profile::users::users', {
  }
  )

  $defaults = {
    'ensure' => present,
  }

  create_resources(group, $groups, $defaults)

  $acc_defaults = {
    'ensure'       => present,
    'shell'        => '/bin/bash',
    'password'     => '!!',
    'create_group' => false,
  }
  create_resources('account', $users, $acc_defaults)
}
