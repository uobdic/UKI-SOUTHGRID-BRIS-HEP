# IPMI profile for DICE
class profile::ipmi() {
  include ipmi

  $network_ip = hiera('profile::ipmi::network_ip', '0.0.0.0')

  ipmi::network { 'lan1':
  type    => 'static',
  ip      => $network_ip,
  netmask => '255.255.255.0',
  gateway => '192.168.1.1',
  }->exec{'Set VLAN':
    command => 'ipmitool lan print 1',
  }

}
