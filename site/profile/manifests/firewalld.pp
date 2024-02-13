# Class for configuring firewalld
# Takes rules in the form of
# profile::firewalld::accepts:
#  'allow ssh from XXX':
#    family: 'ipv4'
#    source: 'XXX'
#    protocol: 'tcp'
# profile::firewalld::drops:
#  'drop ssh from YYY':
#    family: 'ipv6'
#    source: 'YYY'
#    protocol: 'all'
class profile::firewalld {
  include firewalld

  $accept = lookup('profile::firewalld::accepts', Hash, 'deep', {})
  $drop   = lookup('profile::firewalld::drops', Hash, 'deep', {})

  $accept.each | String $comment, Hash $rule | {
    firewalld_rich_rule { $comment:
      ensure   => present,
      zone     => 'public',
      family   => $rule['family'],
      action   => 'accept',
      source   => $rule['source'],
      protocol => $rule['protocol'],
    }
  }

  $drop.each | String $comment, Hash $rule | {
    firewalld_rich_rule { $comment:
      ensure   => present,
      zone     => 'public',
      family   => $rule['family'],
      action   => 'drop',
      source   => $rule['source'],
      protocol => $rule['protocol'],
    }
  }
}
