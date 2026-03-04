# profile::projects::cleanup
#
# Installs helper tooling for conservative leaver cleanup in /dice/projects.
# This class does not run cleanup by itself; it only ensures the script exists.
#
class profile::projects::cleanup {
  file { '/usr/local/sbin/dice-projects-cleanup-user':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profile/projects/dice-projects-cleanup-user',
  }
}
