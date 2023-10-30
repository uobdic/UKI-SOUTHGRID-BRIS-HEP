# Profile for sudo users
class profile::users::admin {
  # purge sudo config and sudoers.d
  class { 'sudo': }
  # collect all users with sudo access
  Array[String] $site_admins = hiera_array('site::admins', [])
  if $facts['node_info']['admins'] == undef {
    fail('node_info.admins is not defined')
  }
  if has_key($facts['node_info'], 'admins') {
    Array[String] $node_admins = $facts['node_info']['admins']
  }
  else {
    Array[String] $node_admins = []
  }
  Array[String] $sudoers = unique($site_admins + $node_admins)
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
