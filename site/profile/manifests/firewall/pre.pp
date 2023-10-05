# Default iptables rules at the beginning of the file
class profile::firewall::pre {
  Firewall {
  require => undef, }

  # avoid purging docker
  firewallchain { 'FORWARD:filter:IPv4':
    purge  => true,
    ignore => [ '[^"]*(?i:docker)[^"]*', 'br-' ],
  }
  firewallchain { 'OUTPUT:filter:IPv4':
    purge  => true,
    ignore => [ '[^"]*(?i:docker)[^"]*' ],
  }
  firewallchain { 'DOCKER:filter:IPv4':
    purge  => false,
  }
  firewallchain { 'DOCKER:nat:IPv4':
    purge  => false,
  }
  firewallchain { 'POSTROUTING:nat:IPv4':
    purge  => true,
    ignore => [ '[^"]*(?i:docker)[^"]*', '172.' ],
  }
  firewallchain { 'PREROUTING:nat:IPv4':
    purge  => true,
    ignore => [ '[^"]*(?i:docker)[^"]*' ],
  }

  # Ensure input rules are cleaned out
  firewallchain { 'INPUT:filter:IPv4':
    ensure => present,
    purge  => true,
  }

  # Default firewall rules
  firewall { '000 accept all icmp':
    proto  => 'icmp',
    action => 'accept',
  }

  firewall { '00001 accept all icmpv6':
    proto  => 'ipv6-icmp',
    action => 'accept',
  }

  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }

  firewall { '002 reject local traffic not on loopback interface':
    iniface     => '! lo',
    proto       => 'all',
    destination => '127.0.0.1/8',
    action      => 'reject',
  }

  firewall { '0001 accept all to lo interface':
    proto    => 'all',
    iniface  => 'lo',
    action   => 'accept',
    provider => 'ip6tables',
  }

  firewall { '003 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  firewall { '0003 accept related established rules':
    proto    => 'all',
    state    => ['RELATED', 'ESTABLISHED'],
    action   => 'accept',
    provider => 'ip6tables',
  }

  firewallchain { 'FORWARD:filter:IPv4':
    purge  => true,
    ignore => ['docker'],
  }
  firewallchain { 'DOCKER:filter:IPv4':
    purge  => false,
  }
  firewallchain { 'DOCKER:nat:IPv4':
    purge  => false,
  }
  firewallchain { 'POSTROUTING:nat:IPv4':
    purge  => true,
    ignore => ['docker', '172.17'],
  }
  firewallchain { 'PREROUTING:nat:IPv4':
    purge  => true,
    ignore => ['DOCKER'],
  }
}
