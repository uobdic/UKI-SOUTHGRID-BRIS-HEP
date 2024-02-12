# Class for configuring firewalld
class profile::firewalld {
  include firewalld

  $accept          = lookup('profile::firewall::accept', Hash, 'deep', {})
  $accept_v6       = lookup('profile::firewall6::accept', Hash, 'deep', {})
  $drop            = lookup('profile::firewall::drop', Hash, 'deep', {})
  $drop_v6         = lookup('profile::firewall6::drop', Hash, 'deep', {})

  # transform the accept and drop hashes into rich rules
  # rules are of the form:
  # comment: {"source": "<ip range>", "proto": <protocol>}

  accept.each | String $comment, Hash $rule | {
    firewalld_rich_rule { $comment:
      ensure   => present,
      zone     => 'public',
      family   => 'ipv4',
      action   => 'accept',
      source   => $rule['source'],
      protocol => $rule['proto'],
    }
  }

  accept_v6.each | String $comment, Hash $rule | {
    firewalld_rich_rule { $comment:
      ensure   => present,
      zone     => 'public',
      family   => 'ipv6',
      action   => 'accept',
      source   => $rule['source'],
      protocol => $rule['proto'],
    }
  }

  drop.each | String $comment, Hash $rule | {
    firewalld_rich_rule { $comment:
      ensure   => present,
      zone     => 'public',
      family   => 'ipv4',
      action   => 'drop',
      source   => $rule['source'],
      protocol => $rule['proto'],
    }
  }

  drop_v6.each | String $comment, Hash $rule | {
    firewalld_rich_rule { $comment:
      ensure   => present,
      zone     => 'public',
      family   => 'ipv6',
      action   => 'drop',
      source   => $rule['source'],
      protocol => $rule['proto'],
    }
  }
}
