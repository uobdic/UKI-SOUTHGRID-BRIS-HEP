# This class is used to install the grid certificate on the LCG nodes
class profile::grid_cert (
  String $cert_store = 'dice_store/certificates',
) {
  $fqdn = $facts['networking']['fqdn']

  file { '/etc/grid-security':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/grid-security/hostcert.pem':
    ensure  => file,
    source  => "puppet:///${cert_store}/${fqdn}_hostcert.pem",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/grid-security'],
  }

  file { '/etc/grid-security/hostkey.pem':
    ensure  => file,
    source  => "puppet:///${cert_store}/${fqdn}_hostkey.pem",
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    require => File['/etc/grid-security'],
  }
}
