class profile::firewall {
  $accept          = hiera_hash('profile::firewall::accept', {})
  $drop            = hiera_hash('profile::firewall::drop', {})
  include profile::firewall::setup

  $accept_defaults = {
    'action' => 'accept',
  }

  $drop_defaults   = {
    'action' => 'drop',
  }

  create_resources('firewall', $accept, $accept_defaults)
  create_resources('firewall', $drop, $drop_defaults)

}
