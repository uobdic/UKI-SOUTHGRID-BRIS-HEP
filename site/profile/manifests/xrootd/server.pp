# Install the Grid host credentials used by the native XRootD server.
class profile::xrootd::server (
  String $cert_store = 'dice_store/certificates',
) {
  $fqdn = $facts['networking']['fqdn']
  $cert_dir = '/etc/grid-security/xrd'

  file { $cert_dir:
    ensure => directory,
    owner  => 'xrootd',
    group  => 'xrootd',
    mode   => '0750',
  }

  file { "${cert_dir}/hostcert.pem":
    ensure => file,
    source => "puppet:///${cert_store}/${fqdn}_hostcert.pem",
    owner  => 'xrootd',
    group  => 'xrootd',
    mode   => '0644',
    notify => Service['xrootd@clustered'],
  }

  file { "${cert_dir}/hostkey.pem":
    ensure    => file,
    source    => "puppet:///${cert_store}/${fqdn}_hostkey.pem",
    owner     => 'xrootd',
    group     => 'xrootd',
    mode      => '0600',
    show_diff => false,
    notify    => Service['xrootd@clustered'],
  }

  # Puppet coalesces refresh events and restarts an already-running unit.
  service { 'xrootd@clustered':
    provider => systemd,
  }
}
