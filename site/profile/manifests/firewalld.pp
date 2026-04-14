# profile::firewalld
#
# Partitions firewalld rules into:
#  - Source-only rules (family+source only) -> enforced via ipsets + 2–4 rich rules total
#  - Everything else (icmp/ports/services/complex matches) -> enforced as normal firewalld_rich_rule resources
#
# Hiera input:
#   profile::firewalld::accepts / profile::firewalld::drops
# Each is a hash:
#   "Human readable title":
#     family: ipv4|ipv6    (optional, defaults to ipv4)
#     source: CIDR         (optional depending on rule)
#     priority: int        (optional)
#     port/service/protocol/... (optional)
#
class profile::firewalld (
  String $zone           = 'public',
  String $notes_path     = '/etc/dice/firewalld_notes.txt',
  String $ipset_prefix   = 'dice',
  Integer $drop_priority = 50,
  Integer $accept_priority = 60,
) {
  include firewalld

  $accepts = lookup('profile::firewalld::accepts', Hash, 'deep', {})
  $drops   = lookup('profile::firewalld::drops',   Hash, 'deep', {})

  $accepts_ipset = $accepts.filter |$title, $rule| {
    $rule =~ Hash and profile::firewalld_ipset_candidate($rule)
  }
  $accepts_rich = $accepts.filter |$title, $rule| {
    !($rule =~ Hash and profile::firewalld_ipset_candidate($rule))
  }

  $drops_ipset = $drops.filter |$title, $rule| {
    $rule =~ Hash and profile::firewalld_ipset_candidate($rule)
  }
  $drops_rich = $drops.filter |$title, $rule| {
    !($rule =~ Hash and profile::firewalld_ipset_candidate($rule))
  }

  # 1) Source-only rules -> ipsets + small number of rich rules
  profile::firewalld::ipsets { 'ipset-lists':
    accepts         => $accepts_ipset,
    drops           => $drops_ipset,
    zone            => $zone,
    notes_path      => $notes_path,
    ipset_prefix    => $ipset_prefix,
    drop_priority   => $drop_priority,
    accept_priority => $accept_priority,
  }

  # 2) Everything else -> normal rich rules (as you do today)
  $accept_defaults = { ensure => present, zone => $zone, action => 'accept' }
  $drop_defaults   = { ensure => present, zone => $zone, action => 'drop' }

  create_resources('firewalld_rich_rule', $accepts_rich, $accept_defaults)
  create_resources('firewalld_rich_rule', $drops_rich,   $drop_defaults)
}
