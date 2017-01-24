#
#  Firewall profile
#
class profile::firewall {
  $accept          = hiera_hash('profile::firewall::accept', {})
  $accept_v6       = hiera_hash('profile::firewall6::accept', {})
  $drop            = hiera_hash('profile::firewall::drop', {})
  $drop_v6         = hiera_hash('profile::firewall6::drop', {})
  include profile::firewall::setup

  $accept_defaults = {
    'action' => 'accept',
  }
  $accept_defaults_v6 = {
    'action' => 'accept',
    'provider' => 'ip6tables'
  }

  $drop_defaults   = {
    'action' => 'drop',
  }
  $drop_defaults_v6   = {
    'action' => 'drop',
    'provider' => 'ip6tables'
  }

  create_resources('firewall', $accept, $accept_defaults)
  create_resources('firewall', $drop, $drop_defaults)

  create_resources('firewall', $accept_v6, $accept_defaults_v6)
  create_resources('firewall', $drop_v6, $drop_defaults_v6)

}
