# default firewall rules
class profile::firewall::default_rules {
  firewall { '100 DROP UoB crash-probes WAS 100 accept SSH from CSE':
    proto  => 'all',
    jump   => 'drop',
    source => '10.17.0.0/16',
  }

  firewall { '100 DROP UoB crash-probes':
    proto  => 'all',
    jump   => 'drop',
    source => '10.18.0.0/15',
  }

  firewall { '101 trust SEIS subnet':
    proto  => 'all',
    jump   => 'accept',
    source => '172.16.0.0/16',
  }

  firewall { '101 trust WIFI 1':
    proto  => 'all',
    jump   => 'accept',
    source => '172.21.0.0/16',
  }

  firewall { '101 trust WIFI 2':
    proto  => 'all',
    jump   => 'accept',
    source => '172.23.0.0/16',
  }

  firewall { '101 trust 5TA wired ntwk':
    proto  => 'all',
    jump   => 'accept',
    source => '172.28.0.0/16',
  }

  firewall { '102 Trust UoB network':
    proto  => 'all',
    jump   => 'accept',
    source => '137.222.0.0/16',
  }

  firewall { '103 Trust DICE network':
    proto  => 'all',
    jump   => 'accept',
    source => '10.129.5.0/24',
  }

  firewall { '104 Trust SM network':
    proto  => 'all',
    jump   => 'accept',
    source => '10.129.1.0/24',
  }

  firewall { '105 drop all-systems.mcast.net':
    proto       => 'igmp',
    jump        => 'drop',
    destination => '224.0.0.1',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 137.222.9.43':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '137.222.9.43/32',
    dport       => '2500-3300',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 172.26.5.15':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '172.26.5.15/32',
    dport       => '2500-3300',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 172.26.5.37':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '172.26.5.37/32',
    dport       => '2500-3300',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 172.26.7.8':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '172.26.7.8/32',
    dport       => '2500-3300',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 172.26.7.24':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '172.26.7.24/32',
    dport       => '2500-3300',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 172.27.5.16':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '172.27.5.16/32',
    dport       => '2500-3300',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 172.27.5.18':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '172.27.5.18/32',
    dport       => '2500-3300',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 172.27.5.22':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '172.27.5.22/32',
    dport       => '2500-3300',
  }

  firewall { '400 allow Veeam restore help ports 2500-3300 172.27.7.2':
    proto       => 'tcp',
    jump        => 'accept',
    destination => '172.27.7.2/32',
    dport       => '2500-3300',
  }
}
