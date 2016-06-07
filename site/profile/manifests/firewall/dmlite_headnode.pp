# Firewall configuration for a DMLite Gateway
class profile::firewall::dmlite_headnode {
  firewall { '950 allow http and https':
    proto  => 'tcp',
    dport  => [80, 443],
    action => 'accept'
  }

  firewall { '950 allow rfio':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '5001',
    action => 'accept'
  }

  firewall { '950 allow rfio range':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '20000-25000',
    action => 'accept'
  }

  firewall { '950 allow gridftp control':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '2811',
    action => 'accept'
  }

  firewall { '950 allow gridftp range':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '20000-25000',
    action => 'accept'
  }

  firewall { '950 allow srmv2.2':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '8446',
    action => 'accept'
  }

  firewall { '950 allow xrootd':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '1095',
    action => 'accept'
  }

  firewall { '950 allow cmsd':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '1094',
    action => 'accept'
  }

  firewall { '950 allow DPNS':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '5010',
    action => 'accept'
  }

  firewall { '950 allow DPM':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '5015',
    action => 'accept'
  }

  firewall { '950 allow bdii':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '2170',
    action => 'accept'
  }
}
