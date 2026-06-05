# Main entry point for xrootd configuration.
class profile::xrootd (
  Enum['server', 'redirector', 'standalone'] $role = 'server',
  String $xrootd_version = '6.0.3-1.el9',
  String $secrets_root = '/.secrets',
  Array[String] $xrootd_packages = [
    'xrootd',
    'xrootd-client',
    'xrootd-scitokens',
    'xrootd-selinux',
    'xrootd-server',
    'xrootd-server-libs',
    'xrootd-voms',
  ],
  Array[String] $support_packages = [
    'cronie',
    'ca-certificates',
    'ca-policy-egi-core',
    'ca-policy-lcg',
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
  $instance = $role ? {
    'standalone' => 'standalone',
    default      => 'clustered',
  }
  $services = $role ? {
    'standalone' => ["xrootd@${instance}"],
    default      => ["xrootd@${instance}", "cmsd@${instance}"],
  }

  if $role == 'server' {
    include profile::xrootd::shoveler
  }

  $versionlock_entries = $xrootd_packages.map |String $package_name| {
    "${package_name}-1:${xrootd_version}.*"
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

  yumrepo { 'xrootd-stable':
    ensure   => present,
    descr    => 'XRootD Stable repository',
    baseurl  => "https://xrootd.web.cern.ch/xrootd/repo/stable/el${os_major}/\$basearch/",
    enabled  => 1,
    gpgcheck => 1,
    gpgkey   => 'https://xrootd.web.cern.ch/xrootd/repo/RPM-GPG-KEY.txt',
    protect  => 0,
  }

  package { $support_packages:
    ensure  => present,
  }

  package { $xrootd_packages:
    ensure          => $xrootd_version,
    install_options => ['--enablerepo=xrootd-stable'],
    require         => [
      Yumrepo['xrootd-stable'],
    ],
  }

  package { 'xrootd-cmstfc':
    ensure          => installed,
    install_options => ['--enablerepo=xrootd-stable'],
    require         => [
      Yumrepo['xrootd-stable'],
    ],
  }

  file { [
      '/etc/lcmaps',
      '/etc/xrootd',
      '/etc/xrootd_info',
    ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
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
    ]:
      ensure => directory,
      owner  => 'xrootd',
      group  => 'xrootd',
      mode   => '0750',
  }

  file { [
      '/var/log/xrootd',
    ]:
      ensure => directory,
      owner  => 'xrootd',
      group  => 'xrootd',
      mode   => '0755',
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

  file { '/etc/grid-security/xrd':
    ensure  => link,
    target  => "${secrets_root}/etc/grid-security/xrd",
    require => File['/etc/grid-security'],
  }

  file { '/etc/xrootd/macaroon-secret':
    ensure  => link,
    target  => "${secrets_root}/etc/xrootd/macaroon-secret",
    require => File['/etc/xrootd'],
  }

  $grid_security_links = {
    # '/etc/grid-security/vomsdir'          => '/cvmfs/grid.cern.ch/etc/grid-security/vomsdir', # we cannot do this since voms rpm needs to overwrite it.
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

  cron { 'fetch-crl':
    ensure  => present,
    command => '/usr/sbin/fetch-crl',
    user    => 'root',
    hour    => 1,
    minute  => 5,
    require => Package['fetch-crl'],
  }
}
