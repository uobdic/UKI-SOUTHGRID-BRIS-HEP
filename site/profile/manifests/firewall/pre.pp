class profile::firewall::pre {
  Firewall {
    require => undef, }

  # Default firewall rules
  firewall { '000 accept all icmp':
    proto    => 'icmp',
    action   => 'accept',
    provider => ['iptables', 'ip6tables'],
  }

  firewall { '001 accept all to lo interface':
    proto    => 'all',
    iniface  => 'lo',
    action   => 'accept',
    provider => ['iptables', 'ip6tables'],
  }

  firewall { '002 reject local traffic not on loopback interface':
    iniface     => '! lo',
    proto       => 'all',
    destination => '127.0.0.1/8',
    action      => 'reject',
  }

  firewall { '003 accept related established rules':
    proto    => 'all',
    state    => ['RELATED', 'ESTABLISHED'],
    action   => 'accept',
    provider => ['iptables', 'ip6tables'],
  }

}
