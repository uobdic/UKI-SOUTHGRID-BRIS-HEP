# Firewall configuration for a DMLite Gateway
class profile::firewall::xrootd_gateway {
  firewall { '940 allow xrootd':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '1094',
    action => 'accept',
  }
  firewall { '941 allow xrootd':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '1194',
    action => 'accept',
  }
  # IPv6
  firewall { '960 allow xrootd':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '1094',
    action   => 'accept',
    provider => 'ip6tables',
  }
  firewall { '961 allow xrootd':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '1194',
    action   => 'accept',
    provider => 'ip6tables',
  }
}
