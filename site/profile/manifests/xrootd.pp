# Main entry point for xrootd configuration.

class profile::xrootd (
  Enum['server', 'redirector', 'standalone'] $role = 'server',
  String $xrootd_version = '6.0.3-1.el9',
  String $osg_release_version = '24-main',
  Integer $xrootd_uid = 1094,
  Integer $xrootd_gid = 1094,
  String $secrets_root = '/.secrets',
  Array[String] $xrootd_packages = [
    'xrootd',
    'xrootd-client',
    'xrootd-cmstfc',
    'xrootd-scitokens',
    'xrootd-selinux',
    'xrootd-server',
    'xrootd-server-libs',
    'xrootd-voms',
  ],
  Array[String] $support_packages = [
    'cronie',
    'fetch-crl',
    'iproute',
    'less',
    'procps-ng',
    'python3-dnf-plugin-versionlock',
    'which',
  ],
  Boolean $manage_services = true,
) {
  $os_major = $facts['os']['release']['major']
  $osg_release_package_name = "osg-${osg_release_version}-el${os_major}-release"
  $osg_release_package_source = "https://repo.opensciencegrid.org/osg/${osg_release_version}/${osg_release_package_name}-latest.rpm"
  $instance = $role ? {
    'standalone' => 'standalone',
    default      => 'clustered',
  }
  $services = $role ? {
    'standalone' => ["xrootd@${instance}"],
    default      => ["xrootd@${instance}", "cmsd@${instance}"],
  }
  $versionlock_entries = $xrootd_packages.map |String $package_name| {
    "${package_name}-0:${xrootd_version}.*"
  }
  $xrootd_service_notify = $manage_services ? {
    true    => Service[$services],
    default => [],
  }

  $xrootd_scripts = [
    'list_installed.sh',
    'scan_versions.sh',
    'xrdcp-tpc.sh',
    'xrdsum.sh',
  ]
  $xrootd_config_files = [
    'Authfile',
    'example_permissions.json',
    'extract_directories.py',
    'initial_setup_hdfs.sh',
    'initial_setup_posix.sh',
    'robots.txt',
    'scitokens.cfg',
    'scitokens_mapfile_cms.json',
    'scitokens_mapfile_wlcg.json',
    'set_permissions_hdfs.py',
    'storage.xml',
    'xrootd-clustered.cfg',
    'xrootd-standalone.cfg',
  ]
  $xrootd_config_d_files = [
    '10-file-catalog.cfg',
    '10-posix.cfg',
    '20-https-and-security.cfg',
    '30-package-marking.cfg',
    '50-monitoring.cfg',
    '90-logging.cfg',
  ]
  $lcmaps_files = [
    'lcmaps.db',
  ]
  $osg_image_config_files = [
    '10-fetch-crl.sh',
    '12-xrd-certs-init.sh',
  ]

  yumrepo { 'xrootd-stable':
    ensure   => present,
    descr    => 'XRootD Stable repository',
    baseurl  => "https://xrootd.web.cern.ch/xrootd/repo/stable/el${os_major}/\$basearch/",
    enabled  => 1,
    gpgcheck => 1,
    gpgkey   => 'https://xrootd.web.cern.ch/xrootd/repo/RPM-GPG-KEY.txt',
    protect  => 0,
  }

  package { $osg_release_package_name:
    ensure => present,
    source => $osg_release_package_source,
  }

  package { $support_packages:
    ensure  => present,
    require => Package[$osg_release_package_name],
  }

  package { $xrootd_packages:
    ensure          => $xrootd_version,
    install_options => ['--enablerepo=xrootd-stable', '--enablerepo=osg-contrib'],
    require         => [
      Yumrepo['xrootd-stable'],
      Package[$osg_release_package_name],
      User['xrootd'],
    ],
  }

  group { 'xrootd':
    ensure => present,
    gid    => $xrootd_gid,
  }

  user { 'xrootd':
    ensure     => present,
    uid        => $xrootd_uid,
    gid        => 'xrootd',
    shell      => '/bin/sh',
    home       => '/var/spool/xrootd',
    managehome => false,
    require    => Group['xrootd'],
  }

  file { [
      '/etc/grid-security',
      '/etc/lcmaps',
      '/etc/osg',
      '/etc/xrootd',
      '/etc/xrootd_info',
    ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
  }

  file { '/etc/osg/image-config.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/osg'],
  }

  file { '/etc/xrootd/config.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/xrootd'],
  }

  file { [
      '/var/run/xrootd',
      '/var/spool/xrootd',
      '/var/log/xrootd',
    ]:
      ensure  => directory,
      owner   => 'xrootd',
      group   => 'xrootd',
      mode    => '0755',
      require => User['xrootd'],
  }

  $xrootd_scripts.each |String $script| {
    file { "/etc/xrootd/${script}":
      ensure  => file,
      source  => "puppet:///modules/profile/etc/xrootd/${script}",
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/etc/xrootd'],
    }
  }

  $xrootd_config_files.each |String $config| {
    file { "/etc/xrootd/${config}":
      ensure  => file,
      source  => "puppet:///modules/profile/etc/xrootd/${config}",
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File['/etc/xrootd'],
      notify  => $xrootd_service_notify,
    }
  }

  $xrootd_config_d_files.each |String $config| {
    file { "/etc/xrootd/config.d/${config}":
      ensure  => file,
      source  => "puppet:///modules/profile/etc/xrootd/config.d/${config}",
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File['/etc/xrootd/config.d'],
      notify  => $xrootd_service_notify,
    }
  }

  $lcmaps_files.each |String $file_name| {
    file { "/etc/lcmaps/${file_name}":
      ensure  => file,
      source  => "puppet:///modules/profile/etc/lcmaps/${file_name}",
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File['/etc/lcmaps'],
    }
  }

  $osg_image_config_files.each |String $file_name| {
    file { "/etc/osg/image-config.d/${file_name}":
      ensure  => file,
      source  => "puppet:///modules/profile/etc/osg/image-config.d/${file_name}",
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File['/etc/osg/image-config.d'],
    }
  }

  file { '/etc/grid-security/xrd':
    ensure  => link,
    target  => "${secrets_root}/etc/grid-security/xrd",
    require => File['/etc/grid-security'],
  }

  file { '/etc/grid-security/hostcert.pem':
    ensure  => link,
    target  => '/etc/grid-security/xrd/hostcert.pem',
    require => File['/etc/grid-security/xrd'],
  }

  file { '/etc/grid-security/hostkey.pem':
    ensure  => link,
    target  => '/etc/grid-security/xrd/hostkey.pem',
    require => File['/etc/grid-security/xrd'],
  }

  file { '/etc/xrootd/macaroon-secret':
    ensure  => link,
    target  => "${secrets_root}/etc/xrootd/macaroon-secret",
    require => File['/etc/xrootd'],
  }

  $grid_security_links = {
    '/etc/grid-security/certificates'     => '/cvmfs/grid.cern.ch/etc/grid-security/certificates',
    '/etc/grid-security/vomsdir'          => '/cvmfs/grid.cern.ch/etc/grid-security/vomsdir',
    '/etc/grid-security/vomses'           => '/cvmfs/grid.cern.ch/etc/grid-security/vomses',
  }

  $grid_security_links.each |String $path, String $target| {
    file { $path:
      ensure  => link,
      target  => $target,
      require => File['/etc/grid-security'],
    }
  }

  file { '/etc/dnf/plugins':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/dnf/plugins/versionlock.list':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    replace => false,
    require => [
      File['/etc/dnf/plugins'],
      Package['python3-dnf-plugin-versionlock'],
    ],
  }

  $versionlock_entries.each |String $versionlock_entry| {
    file_line { "versionlock ${versionlock_entry}":
      path    => '/etc/dnf/plugins/versionlock.list',
      line    => $versionlock_entry,
      require => File['/etc/dnf/plugins/versionlock.list'],
    }
  }

  if $manage_services {
    service { $services:
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/xrootd'],
      require   => [
        Package['xrootd-server'],
        File['/var/run/xrootd'],
        File['/var/spool/xrootd'],
        File['/var/log/xrootd'],
        File['/etc/xrootd/macaroon-secret'],
      ],
    }
  }
}
