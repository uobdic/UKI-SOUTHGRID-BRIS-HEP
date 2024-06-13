class profile::firewall::xrootdse {
  firewall { '940 allow xrootd':
    state => 'NEW',
    proto => 'tcp',
    dport => '1094',
    jump  => 'accept',
  }
  firewall { '940 allow https':
    state => 'NEW',
    proto => 'tcp',
    dport => '443',
    jump  => 'accept',
  }
  # IPv6
  firewall { '960 allow xrootd':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '1094',
    jump     => 'accept',
    protocol => 'ip6tables',
  }
  firewall { '960 allow https':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '443',
    jump     => 'accept',
    protocol => 'ip6tables',
  }
}
