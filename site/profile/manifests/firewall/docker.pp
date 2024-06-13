# Firewall rules for docker service
class profile::firewall::docker {
  # from https://gist.github.com/jessereynolds/986aaa8b93a5b5b8e77a20662017cccd
  firewallchain { [
    'DOCKER-ISOLATION-STAGE-1:filter:IPv4',
    'DOCKER-ISOLATION-STAGE-2:filter:IPv4',
    'DOCKER-USER:filter:IPv4',
    'DOCKER:filter:IPv4',
    'DOCKER:nat:IPv4',
    ]:
    ensure => 'present',
  }

  # filter table
  # FORWARD chain

  firewall { '550 docker FORWARD jump DOCKER-USER':
    chain => 'FORWARD',
    jump  => 'DOCKER-USER',
    proto => 'all',
    table => 'filter',
  }

  firewall { '551 docker FORWARD jump DOCKER-ISOLATION-STAGE-1':
    chain => 'FORWARD',
    jump  => 'DOCKER-ISOLATION-STAGE-1',
    proto => 'all',
    table => 'filter',
  }

  firewall { '552 docker FORWARD out docker0 related established':
    chain    => 'FORWARD',
    jump     => 'accept',
    proto    => 'all',
    outiface => 'docker0',
    table    => 'filter',
    ctstate  => ['ESTABLISHED', 'RELATED'],
  }

  firewall { '553 docker FORWARD out docker0 jump DOCKER':
    chain    => 'FORWARD',
    jump     => 'DOCKER',
    proto    => 'all',
    outiface => 'docker0',
    table    => 'filter',
  }

  firewall { '554 docker FORWARD in docker0 out not docker0 accept':
    chain    => 'FORWARD',
    jump     => 'accept',
    proto    => 'all',
    iniface  => 'docker0',
    outiface => '! docker0',
    table    => 'filter',
  }

  firewall { '555 docker FORWARD in docker0 out docker0 accept':
    chain    => 'FORWARD',
    jump     => 'accept',
    proto    => 'all',
    iniface  => 'docker0',
    outiface => 'docker0',
    table    => 'filter',
  }

  # other chains

  firewall { '556 docker DOCKER-ISOLATION-STAGE-1 in docker0 out not docker0 jump DOCKER-ISOLATION-STAGE-2':
    chain    => 'DOCKER-ISOLATION-STAGE-1',
    iniface  => 'docker0',
    jump     => 'DOCKER-ISOLATION-STAGE-2',
    outiface => '! docker0',
    proto    => 'all',
    table    => 'filter',
  }

  firewall { '557 docker DOCKER-ISOLATION-STAGE-1 jump RETURN':
    chain => 'DOCKER-ISOLATION-STAGE-1',
    jump  => 'RETURN',
    proto => 'all',
    table => 'filter',
  }

  firewall { '558 docker DOCKER-ISOLATION-STAGE-2 out docker0 drop':
    jump     => 'drop',
    chain    => 'DOCKER-ISOLATION-STAGE-2',
    outiface => 'docker0',
    proto    => 'all',
    table    => 'filter',
  }

  firewall { '559 docker DOCKER-ISOLATION-STAGE-2 jump RETURN':
    chain => 'DOCKER-ISOLATION-STAGE-2',
    jump  => 'RETURN',
    proto => 'all',
    table => 'filter',
  }

  firewall { '560 docker DOCKER-USER jump RETURN':
    chain => 'DOCKER-USER',
    jump  => 'RETURN',
    proto => 'all',
    table => 'filter',
  }


  # nat table

  # what about 'ADDRTYPE match' option?
  firewall { '561 docker nat PREROUTING jump DOCKER':
    chain    => 'PREROUTING',
    jump     => 'DOCKER',
    proto    => 'all',
    table    => 'nat',
    dst_type => 'LOCAL',
  }

  # what about 'ADDRTYPE match' option?
  firewall { '562 docker nat OUTPUT jump DOCKER':
    chain       => 'OUTPUT',
    jump        => 'DOCKER',
    destination => '! 127.0.0.0/8',
    proto       => 'all',
    table       => 'nat',
    dst_type    => 'LOCAL',
  }

  firewall { '563 docker nat POSTROUTING out not docker0 jump MASQUERADE':
    chain    => 'POSTROUTING',
    jump     => 'MASQUERADE',
    proto    => 'all',
    outiface => '! docker0',
    source   => '172.17.0.0/16',
    table    => 'nat',
  }

  firewall { '564 docker nat DOCKER jump RETURN':
    chain   => 'DOCKER',
    jump    => 'RETURN',
    proto   => 'all',
    iniface => 'docker0',
    table   => 'nat',
  }
}
