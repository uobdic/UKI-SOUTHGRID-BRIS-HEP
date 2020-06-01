class profile::firewall::default_rules {
  firewall { '100 DROP UoB crash-probes WAS 100 accept SSH from CSE':
    proto  => 'all',
    action => 'drop',
    source => '10.17.0.0/16',
  }
  
  firewall { '100 DROP UoB crash-probes':
     proto => 'all',
     action => 'drop',
     source => '10.18.0.0/15',
  }

  firewall { '101 trust WIFI 1':
    proto  => 'all',
    action => 'accept',
    source => '172.21.0.0/16',
  }

  firewall { '101 trust WIFI 2':
    proto  => 'all',
    action => 'accept',
    source => '172.23.0.0/16',
  }

  firewall { '102 Trust UoB network':
    proto  => 'all',
    action => 'accept',
    source => '137.222.0.0/16',
  }

  firewall { '103 Trust DICE network':
    proto  => 'all',
    action => 'accept',
    source => '10.129.5.0/24',
  }

  firewall { '104 Trust SM network':
    proto  => 'all',
    action => 'accept',
    source => '10.129.1.0/24',
  }

  firewall { '105 drop all-systems.mcast.net':
    proto       => 'igmp',
    action      => 'drop',
    destination => '224.0.0.1',
  }
}
