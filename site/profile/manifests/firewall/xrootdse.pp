class profile::firewall::xrootdse {
  firewall { '950 allow xrootd':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '1094',
    action   => 'accept',
  }
  firewall { '960 allow https':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '443',
    action   => 'accept',
  }
  # IPv6
  firewall { '950 allow xrootd':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '1094',
    action   => 'accept',
    provider => 'ip6tables',
  }
  firewall { '960 allow https':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '443',
    action   => 'accept',
    provider => 'ip6tables',
  }
}
