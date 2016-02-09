class profile::firewall::post {
  # after everything
  firewall { '9996 Log once all DROPs are done':
    proto      => 'all',
    jump       => 'LOG',
    log_prefix => '[iptables]: '
  }

  firewall { '9997 drop all':
    chain  => 'INPUT',
    proto  => 'all',
    action => 'drop',
    before => undef,
  }

  firewall { '9998 drop all':
    chain  => 'FORWARD',
    proto  => 'all',
    action => 'drop',
    before => undef,
  }

  firewall { '9999 Reject anything else':
    proto  => 'all',
    action => 'reject',
    reject => 'icmp-host-prohibited',
  }

}
