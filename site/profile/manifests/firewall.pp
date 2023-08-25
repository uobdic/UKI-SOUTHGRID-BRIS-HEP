#
#  Firewall profile
#
class profile::firewall {
  $firewall_type   = lookup('node_info::firewall', String, 'deep', 'iptables')

  # if firewall_type is iptables or does not start with firewalld, use iptables
  # otherwise use firewalld
  if $firewall_type == 'iptables' or ! $firewall_type =~ /^firewalld/ {
    # use iptables
    $accept          = lookup('profile::firewall::accept', Hash, 'deep', {})
    $accept_v6       = lookup('profile::firewall6::accept', Hash, 'deep', {})
    $drop            = lookup('profile::firewall::drop', Hash, 'deep', {})
    $drop_v6         = lookup('profile::firewall6::drop', Hash, 'deep', {})

    $accept_defaults = {
      'action' => 'accept',
    }
    $accept_defaults_v6 = {
      'action' => 'accept',
      'provider' => 'ip6tables',
    }

    $drop_defaults   = {
      'action' => 'drop',
      'proto' => 'all',
    }
    $drop_defaults_v6   = {
      'action' => 'drop',
      'provider' => 'ip6tables',
      'proto' => 'all',
    }
    include profile::firewall::setup
    create_resources('firewall', $accept, $accept_defaults)
    create_resources('firewall', $drop, $drop_defaults)

    create_resources('firewall', $accept_v6, $accept_defaults_v6)
    create_resources('firewall', $drop_v6, $drop_defaults_v6)
  } else {
    include profile::firewalld::setup
  }
}
