# IPMI profile for DICE
class profile::ipmi() {
  include ipmi

  $network_ip = lookup('profile::ipmi::network_ip', undef, undef, '0.0.0.0')
  $ipmi_user = lookup('ipmi::user::user', undef, undef, '')
  $ipmi_pw = lookup('ipmi::user::password', undef, undef, '')

  unless $network_ip == '0.0.0.0'{
    ipmi::network { 'lan1':
      type    => 'static',
      ip      => $network_ip,
      netmask => '255.255.255.0',
      gateway => '10.129.13.250',
    }->exec{'set VLAN':
      command     => 'ipmitool lan set 1 vlan id 715',
      path        => ['/usr/bin', '/usr/sbin',],
      refreshonly => true,
    }
  }

  unless $ipmi_user == '' {
    ipmi::user { $ipmi_user:
      user     => $ipmi_user,
      password => $ipmi_pw,
      user_id  => 2,
    }
  }
}
