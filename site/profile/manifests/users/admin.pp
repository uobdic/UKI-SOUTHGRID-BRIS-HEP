# Profile for sudo users
class profile::users::admin {
  # purge sudo config and sudoers.d
  class { 'sudo': }
  # collect all users with sudo access
  $site_admins = hiera_array('site::admins', [])
  $node_admins = $facts['node_info']['admins'] or []
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
