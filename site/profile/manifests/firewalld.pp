# profile::firewalld
#
# Efficient source allow/deny lists for firewalld using ipsets + a small number of rich rules.
#
# Data model (Hiera):
#   profile::firewalld::accepts:
#     "Human-readable reason (CIDR)":
#       family: ipv4|ipv6   # optional (defaults to ipv4)
#       source: "1.2.3.0/24" or "2a03:2880::/29"   # required
#       priority: 100       # optional (used only for notes; ipset rules use fixed priorities)
#
#   profile::firewalld::drops: (same structure)
#
# Parameters:
#   - zone: Firewalld zone to attach the ipset rich rules to (default: public)
#   - notes_path: Where to write a human-readable list of entries with reasons
#   - ipset_prefix: Prefix for created ipset names/files (default: dice)
#   - drop_priority / accept_priority: Rich rule priorities for the ipset-based rules
#
class profile::firewalld (
  Hash   $accepts        = lookup('profile::firewalld::accepts', Hash, 'deep', {}),
  Hash   $drops          = lookup('profile::firewalld::drops',   Hash, 'deep', {}),
  String $zone           = 'public',
  String $notes_path     = '/etc/dice/firewalld_notes.txt',
  String $ipset_prefix   = 'dice',
  Integer $drop_priority = 50,
  Integer $accept_priority = 60,
) {
  include firewalld

  profile::firewalld::ipsets { 'ipset-lists':
    accepts         => $accepts,
    drops           => $drops,
    zone            => $zone,
    notes_path      => $notes_path,
    ipset_prefix    => $ipset_prefix,
    drop_priority   => $drop_priority,
    accept_priority => $accept_priority,
  }
}
