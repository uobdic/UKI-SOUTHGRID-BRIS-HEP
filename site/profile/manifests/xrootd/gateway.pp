# profile for the xrootd manager (there can be more than one - can construct a hierarchy)
class profile::xrootd::gateway {
  include profile::firewall::docker
  firewall { '950 allow xrootd primary port':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '1094',
    action => 'accept',
  }

  firewall { '950 allow xrootd primary port':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '1094',
    action   => 'accept',
    provider => 'ip6tables',
  }

  firewall { '950 allow xrootd secondary port':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '1194',
    action => 'accept',
  }

  firewall { '950 allow xrootd secondary port':
    state    => 'NEW',
    proto    => 'tcp',
    dport    => '1194',
    action   => 'accept',
    provider => 'ip6tables',
  }
}
