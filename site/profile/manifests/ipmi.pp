# IPMI profile for DICE
class profile::ipmi() {
  include ipmi

  $network_ip = hiera('profile::ipmi::network_ip', '0.0.0.0')

  unless $network_ip == '0.0.0.0'{
    ipmi::network { 'lan1':
      type    => 'static',
      ip      => $network_ip,
      netmask => '255.255.255.0',
      gateway => '10.129.13.250',
    }->exec{'set VLAN':
      command => 'ipmitool lan set 1 vlan id 715',
      path    => ['/usr/bin', '/usr/sbin',],
    }
  }
}
