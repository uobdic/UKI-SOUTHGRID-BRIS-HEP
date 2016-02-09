# Clears rules and sets up pre and post classes
class profile::firewall::setup {
  include profile::firewall::pre
  include ::firewall
  include profile::firewall::post

  resources { 'firewall': purge => true }

  Firewall {
    before  => Class['profile::firewall::post'],
    require => Class['profile::firewall::pre'],
  }
}
