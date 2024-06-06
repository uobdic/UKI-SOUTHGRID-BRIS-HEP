# Profile for sudo users
class profile::users::admin {
  $node_role = fact('node_info.role')
  unless $node_role == 'desktop' or $node_role == undef {
    include sudo
    # collect all users with sudo access
    $site_admins = hiera_array('site::admins', [])
    $node_admins = get($facts['node_info'], 'admins', [])

    $sudoers = unique($site_admins + $node_admins)
    # create sudoers config for each user
    $sudoers.each |$user| {
      sudo::conf { $user:
        priority => 10,
        content  => "${user} ALL=(ALL) NOPASSWD: ALL",
      }
    }
    # ensure backwards compatibility for local-sudo:
    sudo::conf { 'local-sudo':
      priority => 10,
      content  => '%local-sudo ALL=(ALL) NOPASSWD: ALL',
    }
  }
}
