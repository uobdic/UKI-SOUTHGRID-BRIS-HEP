# profile/manifests/network/nmconnection.pp
class profile::network::nmconnection {
  $defaults  = lookup('site::network_defaults', Hash, 'first', {})
  $node_info = lookup('site::node_info', Hash, 'first', {})
  $network   = $node_info.dig('network') ? {
    undef   => {},
    default => $node_info.dig('network'),
  }

  if $network.dig('connection') {
    profile::network::nmconnection::interface { $network['connection']:
      ipv4        => $network['ipv4'],
      ipv6        => $network.dig('ipv6'),
      gateway4    => $network.dig('gateway4') ? {
        undef   => $defaults['gateway4'],
        default => $network['gateway4'],
      },
      gateway6    => $network.dig('gateway6') ? {
        undef   => $defaults['gateway6'],
        default => $network['gateway6'],
      },
      mtu         => $network.dig('mtu') ? {
        undef   => $defaults['mtu'],
        default => $network['mtu'],
      },
      dns4        => $network.dig('dns4') ? {
        undef   => $defaults['dns4'],
        default => $network['dns4'],
      },
      dns6        => $network.dig('dns6') ? {
        undef   => $defaults['dns6'],
        default => $network['dns6'],
      },
      ipv6_prefix => $network.dig('ipv6_prefix') ? {
        undef   => $defaults.dig('ipv6_prefix'),
        default => $network['ipv6_prefix'],
      },
    }
  }
}
