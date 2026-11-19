# puppet class to create local users
class profile::users (
  $shell = '/sbin/nologin',
  Boolean $nfs_homes = true, # false: local /home, no /users symlinks
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
    'managehome'   => !$nfs_homes,
    'gid'          => '100',
    'group'        => 'users',
    'tag'          => 'accounts::users',
  }
  # make sure groups are created before users
  Group<| tag == 'accounts::groups' |> -> Accounts::User<| tag == 'accounts::users' |>

  create_resources('group', $groups, $defaults)
  # ssh keys are deployed by accounts only where homes are local; on NFS-home
  # nodes /users is shared and the keys are managed on sts (see below)
  $account_users = Hash($users.map |$name, $acct| {
    $nfs_homes ? {
      true    => [$name, $acct - 'sshkeys'],
      default => [$name, $acct],
    }
  })
  create_resources('accounts::user', $account_users, $acc_defaults)

  if $fqdn == 'sts.dice.priv' {
    $users.each |$key, $value| {
      unless $value['ensure'] == 'absent' {
        file { ["/exports/users/${key}", "/exports/software/${key}", "/exports/scratch/${key}", "/dice/users/${key}"]:
          ensure => directory,
          owner  => $key,
          group  => $acc_defaults['group'],
          mode   => '0700',
        }
        # set quota for cephfs
        $quota = lookup("profile::users::${key}::cephfs_quota", Integer, 'deep', $default_cephfs_quota)
        exec { "set_cephfs_quota /dice/users/${key}":
          command => "/usr/bin/setfattr -n ceph.quota.max_bytes -v ${$quota} /dice/users/${key}",
          unless  => "/usr/bin/getfattr -n ceph.quota.max_bytes /dice/users/${key}",
          require => File["/dice/users/${key}"],
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
        # deploy ssh keys from hieradata into the exported home
        $sshkeys = $value['sshkeys'].lest || { [] }
        $sshkeys.each |$line| {
          $parts = split($line, ' ')
          ssh_authorized_key { "${key}:${parts[2]}":
            ensure  => present,
            user    => $key,
            type    => $parts[0],
            key     => $parts[1],
            target  => "/exports/users/${key}/.ssh/authorized_keys",
            require => File["/exports/users/${key}/.ssh/authorized_keys"],
          }
        }
      }
    }
  }
  # symlink to the correct location (/home -> /users) for each user
  # (only on nodes that mount /users from NFS)
  if $nfs_homes and $fqdn != 'sts.dice.priv' {
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
