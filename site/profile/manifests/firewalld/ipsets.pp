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

  # Helper: manage one ipset + one rich rule referencing it
  $manage_ipset = |String $name, String $family, Array[String] $nets, String $action, Integer $priority| {
    $xml_family = $family ? { 'ipv4' => 'inet', 'ipv6' => 'inet6' }
    $ipset_name = "${ipset_prefix}-${name}-${family}"         # e.g. dice-accept-ipv4
    $ipset_file = "/etc/firewalld/ipsets/${ipset_name}.xml"

    file { $ipset_file:
      ensure  => file,
      mode    => '0644',
      content => epp('profile/firewalld/ipset.xml.epp', {
          'name'    => $ipset_name,
          'family'  => $xml_family,
          'entries' => $nets,
      }),
      notify  => Exec['firewalld-reload-for-ipsets'],
      require => File['/etc/firewalld/ipsets'],
    }

    # Use ipset as the rich rule source (puppet-firewalld supports source hash with ipset key)
    firewalld_rich_rule { "DICE ipset ${name} ${family}":
      ensure   => present,
      zone     => $zone,
      family   => $family,
      source   => { 'ipset' => $ipset_name },
      action   => $action,
      priority => $priority,
      require  => File[$ipset_file],
    }
  }

  # IPv4 (only if there are entries)
  if !empty($drop_v4_nets) { $manage_ipset('drop',   'ipv4', $drop_v4_nets,   'drop',   $drop_priority) }
  if !empty($accept_v4_nets) { $manage_ipset('accept', 'ipv4', $accept_v4_nets, 'accept', $accept_priority) }

  # IPv6 (may be empty on internal nodes)
  if !empty($drop_v6_nets) { $manage_ipset('drop',   'ipv6', $drop_v6_nets,   'drop',   $drop_priority) }
  if !empty($accept_v6_nets) { $manage_ipset('accept', 'ipv6', $accept_v6_nets, 'accept', $accept_priority) }

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
