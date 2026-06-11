# profile/manifests/network/nmconnection/interface.pp
define profile::network::nmconnection::interface (
  String $ipv4,
  Optional[String] $ipv6 = undef,
  String $gateway4,
  String $gateway6,
  Integer $mtu,
  Array[String] $dns4,
  Array[String] $dns6,
  String $ipv6_prefix,
) {
  $ipv4_addr = split($ipv4, '/')[0]
  $ipv4_mask = split($ipv4, '/')[1]
  $octets    = split($ipv4_addr, '[.]')

  $derived_ipv6 = "${ipv6_prefix}:${octets[0]}:${octets[1]}:${octets[2]}:${octets[3]}/64"

  $effective_ipv6 = $ipv6 ? {
    undef   => $derived_ipv6,
    default => $ipv6,
  }

  $conn_file = "/etc/NetworkManager/system-connections/${title}.nmconnection"

  file { $conn_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => epp('profile/etc/NetworkManager/system-connections/static.nmconnection.epp', {
        'connection' => $title,
        'ipv4'       => $ipv4,
        'ipv6'       => $effective_ipv6,
        'gateway4'   => $gateway4,
        'gateway6'   => $gateway6,
        'mtu'        => $mtu,
        'dns4'        => $dns4,
        'dns6'        => $dns6,
    notify  => Exec["nmcli-reload-${title}"],
  }

  exec { "nmcli-reload-${title}":
    command     => "/usr/bin/nmcli connection reload && /usr/bin/nmcli connection up '${title}'",
    refreshonly => true,
  }
}
