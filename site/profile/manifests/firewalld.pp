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
  resources { 'firewall': purge => true }

  $accept = lookup('profile::firewalld::accepts', Hash, 'deep', {})
  $drop   = lookup('profile::firewalld::drops', Hash, 'deep', {})

  $accept_defaults = {
    'ensure'   => present,
    'zone'   => 'public',
    'action'   => 'accept',
    'protocol' => 'tcp',
  }
  create_resources('firewalld_rich_rule', $accept, $accept_defaults)

  $drop_defaults = {
    'ensure'   => present,
    'zone'   => 'public',
    'action'   => 'drop',
    'protocol' => 'tcp',
  }
  create_resources('firewalld_rich_rule', $drop, $drop_defaults)
}
