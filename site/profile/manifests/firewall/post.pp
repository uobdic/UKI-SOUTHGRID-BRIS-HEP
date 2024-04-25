# firewall rules at the end of the chain
class profile::firewall::post {
  # after pre, before custom rules
  firewall { '199 Reject anything else - IPv6':
    chain    => 'FORWARD',
    proto    => 'all',
    jump     => 'reject',
    reject   => 'icmp6-adm-prohibited',
    before   => undef,
    provider => 'ip6tables',
  }

  firewall { '199 Reject anything else':
    chain    => 'FORWARD',
    proto    => 'all',
    jump     => 'reject',
    reject   => 'icmp-host-prohibited',
    before   => undef,
    provider => 'iptables',
  }

  # after everything
  firewall { '99997 Log once all DROPs are done':
    proto      => 'all',
    jump       => 'LOG',
    log_prefix => '[iptables]: ',
    before     => undef,
    provider   => ['iptables', 'ip6tables'],
  }

  firewall { '99998 Reject anything else - IPv6':
    proto    => 'all',
    jump     => 'reject',
    reject   => 'icmp6-adm-prohibited',
    before   => undef,
    provider => 'ip6tables',
  }

  firewall { '99998 Reject anything else':
    proto    => 'all',
    jump     => 'reject',
    reject   => 'icmp-host-prohibited',
    before   => undef,
    provider => 'iptables',
  }
}
