# Clears rules and sets up pre and post classes
class profile::firewall {
  include profile::firewall::pre
  include profile::firewall::post

  resources { 'firewall': purge => true }

  resources { 'firewallchain': purge => true, }

  Firewall {
    before  => Class['profile::firewall::post'],
    require => Class['profile::firewall::pre'],
  }

  class { 'firewall':
  }
}
