class profile::users {
  $groups       = hiera_hash('profile::users::groups', {
  }
  )
  $users        = hiera_hash('profile::users::users', {
  }
  )
  $shell        = hiera('profile::users::shell', '/bin/bash')

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
    create_resources(group, $groups, $defaults)
    create_resources('account', $users, $acc_defaults)
  }
}
