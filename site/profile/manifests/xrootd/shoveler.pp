class profile::xrootd::shoveler (
  String  $stomp_url           = 'dashb-lb-mb.cern.ch:61123',
  String  $stomp_topic         = '/topic/xrootd.shoveler.cms',
  String  $listen_ip           = '0.0.0.0',
  Integer $listen_port         = 9993,
  Boolean $verify              = true,
  Boolean $metrics_enable      = true,
  Integer $metrics_port        = 9994,
  String  $queue_directory     = '/var/spool/shoveler-queue',
  String  $ssl_cert_dir        = '/etc/grid-security/certificates',
  String $stomp_cert = '/etc/grid-security/shoveler/hostcert.pem',
  String $stomp_key  = '/etc/grid-security/shoveler/hostkey.pem',
) {
  package { 'xrootd-monitoring-shoveler':
    ensure => installed,
  }

  file { [
      '/etc/grid-security/shoveler',
      $queue_directory,
    ]:
      ensure => directory,
      owner  => 'xrootd-monitoring-shoveler',
      group  => 'xrootd-monitoring-shoveler',
      mode   => '0755',
  }

  exec { 'copy-shoveler-hostcert':
    command => '/usr/bin/install -o root -g xrootd-monitoring-shoveler -m 0644 /etc/grid-security/hostcert.pem /etc/grid-security/shoveler/hostcert.pem',
    unless  => '/usr/bin/test /etc/grid-security/shoveler/hostcert.pem -nt /etc/grid-security/hostcert.pem',
    require => File['/etc/grid-security/shoveler'],
    notify  => Service['xrootd-monitoring-shoveler'],
  }

  exec { 'copy-shoveler-hostkey':
    command => '/usr/bin/install -o root -g xrootd-monitoring-shoveler -m 0640 /etc/grid-security/hostkey.pem /etc/grid-security/shoveler/hostkey.pem',
    unless  => '/usr/bin/test /etc/grid-security/shoveler/hostkey.pem -nt /etc/grid-security/hostkey.pem',
    require => File['/etc/grid-security/shoveler'],
    notify  => Service['xrootd-monitoring-shoveler'],
  }

  file { '/etc/sysconfig/xrootd-monitoring-shoveler':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => epp('profile/etc/sysconfig/xrootd-monitoring-shoveler.epp', {
        'stomp_url'       => $stomp_url,
        'stomp_topic'     => $stomp_topic,
        'listen_ip'       => $listen_ip,
        'listen_port'     => $listen_port,
        'verify'          => $verify,
        'metrics_enable'  => $metrics_enable,
        'metrics_port'    => $metrics_port,
        'queue_directory' => $queue_directory,
        'ssl_cert_dir'    => $ssl_cert_dir,
        'stomp_cert'      => $stomp_cert,
        'stomp_key'       => $stomp_key,
    }),
    require => Package['xrootd-monitoring-shoveler'],
    notify  => Service['xrootd-monitoring-shoveler'],
  }

  service { 'xrootd-monitoring-shoveler':
    ensure  => running,
    enable  => true,
    require => [
      Package['xrootd-monitoring-shoveler'],
      File['/etc/sysconfig/xrootd-monitoring-shoveler'],
    ],
  }
}
