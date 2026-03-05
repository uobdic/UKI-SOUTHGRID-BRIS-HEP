# profile::firewalld::ipsets
#
# Turns many per-CIDR rich rules into:
#   - up to 4 ipset XML files (accept/drop × inet/inet6)
#   - up to 4 rich rules that reference those ipsets
#   - a notes file preserving the original titles (reasons)
#
# It only creates an ipset + rule if there is at least one entry for that family.
#
define profile::firewalld::ipsets (
  Hash   $accepts,
  Hash   $drops,
  String $zone,
  String $notes_path,
  String $ipset_prefix = 'dice',
  Integer $drop_priority = 50,
  Integer $accept_priority = 60,
) {
  # Normalize incoming hashes into arrays of {title,family,source,priority}
  $accept_entries = $accepts.map |$title, $rule| {
    {
      'title'    => $title,
      'family'   => pick($rule['family'], 'ipv4'),
      'source'   => $rule['source'],
      'priority' => $rule['priority'],
    }
  }

  $drop_entries = $drops.map |$title, $rule| {
    {
      'title'    => $title,
      'family'   => pick($rule['family'], 'ipv4'),
      'source'   => $rule['source'],
      'priority' => $rule['priority'],
    }
  }

  $accept_v4_nets = $accept_entries.filter |$e| { $e['family'] == 'ipv4' }.map |$e| { $e['source'] }.unique.sort
  $accept_v6_nets = $accept_entries.filter |$e| { $e['family'] == 'ipv6' }.map |$e| { $e['source'] }.unique.sort
  $drop_v4_nets   = $drop_entries.filter   |$e| { $e['family'] == 'ipv4' }.map |$e| { $e['source'] }.unique.sort
  $drop_v6_nets   = $drop_entries.filter   |$e| { $e['family'] == 'ipv6' }.map |$e| { $e['source'] }.unique.sort

  # Ensure directory exists
  file { '/etc/firewalld/ipsets':
    ensure => directory,
    mode   => '0755',
  }

  # Reload once if any ipset file changes (firewalld reads ipset XML on reload)
  exec { 'firewalld-reload-for-ipsets':
    command     => '/usr/bin/firewall-cmd --reload',
    refreshonly => true,
    path        => ['/usr/bin', '/bin'],
  }

  if !empty($drop_v4_nets) {
    profile::firewalld::ipset { 'drop':
      entries      => $drop_v4_nets,
      family       => 'ipv4',
      action       => 'drop',
      zone         => $zone,
      priority     => $drop_priority,
      ipset_prefix => $ipset_prefix,
    }
  }

  if !empty($accept_v4_nets) {
    profile::firewalld::ipset { 'accept':
      entries      => $accept_v4_nets,
      family       => 'ipv4',
      action       => 'accept',
      zone         => $zone,
      priority     => $accept_priority,
      ipset_prefix => $ipset_prefix,
    }
  }

  if !empty($drop_v6_nets) {
    profile::firewalld::ipset { 'drop-v6':
      entries      => $drop_v6_nets,
      family       => 'ipv6',
      action       => 'drop',
      zone         => $zone,
      priority     => $drop_priority,
      ipset_prefix => $ipset_prefix,
    }
  }

  if !empty($accept_v6_nets) {
    profile::firewalld::ipset { 'accept-v6':
      entries      => $accept_v6_nets,
      family       => 'ipv6',
      action       => 'accept',
      zone         => $zone,
      priority     => $accept_priority,
      ipset_prefix => $ipset_prefix,
    }
  }

  # Notes file with human context (titles + CIDRs)
  file { $notes_path:
    ensure  => file,
    mode    => '0644',
    content => epp('profile/firewalld/notes.txt.epp', {
        'accept_entries'  => $accept_entries,
        'drop_entries'    => $drop_entries,
        'zone'            => $zone,
        'ipset_prefix'    => $ipset_prefix,
        'drop_priority'   => $drop_priority,
        'accept_priority' => $accept_priority,
    }),
  }
}
