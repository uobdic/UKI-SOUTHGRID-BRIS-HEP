# profile::firewalld::ipset
#
# Manage a single firewalld ipset and the rich rule referencing it.
#
# Parameters:
# @param family       - ipv4 or ipv6
# @param entries      - array of CIDRs
# @param action       - accept or drop
# @param zone         - firewalld zone
# @param priority     - rich rule priority
# @param ipset_prefix - prefix for ipset names (e.g. "dice")
#
define profile::firewalld::ipset (
  Array[String] $entries,
  String $family,
  String $action,
  String $zone,
  Integer $priority,
  String $ipset_prefix = 'dice',
) {
  $xml_family = $family ? {
    'ipv4' => 'inet',
    'ipv6' => 'inet6',
  }

  $ipset_name = "${ipset_prefix}-${family}"
  $ipset_file = "/etc/firewalld/ipsets/${ipset_name}.xml"

  file { $ipset_file:
    ensure  => file,
    mode    => '0644',
    content => epp('profile/firewalld/ipset.xml.epp', {
        'name'    => $ipset_name,
        'family'  => $xml_family,
        'entries' => $entries,
    }),
    notify  => Exec['firewalld-reload-for-ipsets'],
    require => [
      File[$ipset_file],
      Exec['firewalld-reload-for-ipsets'],
    ],
  }

  firewalld_rich_rule { "DICE ipset ${title} ${family}":
    ensure   => present,
    zone     => $zone,
    family   => $family,
    source   => { 'ipset' => $ipset_name },
    action   => $action,
    priority => $priority,
    require  => File[$ipset_file],
  }
}
