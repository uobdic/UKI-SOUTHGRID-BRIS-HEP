# puppet class to create local users
class profile::users (
  $shell = '/sbin/nologin',
) {
  $groups     = lookup('profile::users::groups', Hash, 'deep', {})
  $users      = lookup('profile::users::users', Hash, 'deep', {})
  $default_cephfs_quota = 1100000000000

  if empty($groups) {
    notice('No profile::users::groups specified')
  }

  if empty($users) {
    notice('No profile::users::users specified')
  }
  $node_info = lookup('site::node_info', Hash)
  $fqdn = $facts['networking']['fqdn']

  $defaults     = {
    'ensure' => present,
    'tag'    => 'accounts::groups',
  }

  $acc_defaults = {
    'ensure'       => present,
    'shell'        => $shell,
    'password'     => '!!',
    'create_group' => false,
    'managehome'   => false,
    'gid'          => '100',
    'group'        => 'users',
    'tag'          => 'accounts::users',
  }
  # make sure groups are created before users
  Group<| tag == 'accounts::groups' |> -> Accounts::User<| tag == 'accounts::users' |>

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
        # make sure .ssh/authorized_keys is created for each user
        file { "/exports/users/${key}/.ssh":
          ensure => directory,
          owner  => $key,
          group  => $acc_defaults['group'],
          mode   => '0700',
        } -> file { "/exports/users/${key}/.ssh/authorized_keys":
          ensure => file,
          owner  => $key,
          group  => $acc_defaults['group'],
          mode   => '0600',
        }
      }
    }
  }
  # symlink to the correct location (/home -> /users) for each user
  unless $fqdn == 'sts.dice.priv' {
    $users.each |$key, $value| {
      # remove existing symlinks
      if $value['ensure'] == 'absent' {
        ['home', 'users'].each |$dir| {
          exec { "remove_${dir}_symlink_${key}":
            command => "/usr/bin/rm -f /${dir}/${key}",
            onlyif  => "/usr/bin/test -L /${dir}/${key}",
          }
        }
      }
      # create symlinks: /home -> /users and /users -> /home
      if $value['ensure'] == 'present' or $value['ensure'] == undef {
        exec { "create_home_symlink_${key}":
          command => "/usr/bin/ln -s /users/${key} /home/${key}",
          unless  => "/usr/bin/test -d /home/${key} || /usr/bin/test -L /home/${key}",
        }
        exec { "create_users_symlink_${key}":
          command => "/usr/bin/ln -s /home/${key} /users/${key}",
          unless  => "/usr/bin/test -d /users/${key} || /usr/bin/test -L /users/${key}",
        }
      }
    }
  }
}
