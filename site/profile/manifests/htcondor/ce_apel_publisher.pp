class profile::htcondor::ce_apel_publisher (
  String $apel_db_name,
  String $apel_db_user,
  Sensitive[String] $apel_db_password,
  Sensitive[String] $apel_db_root_password,
  Boolean $apel_enable_ssm = true,
) {
  $site_info = $facts['site_info']
  $goc_site_name = $site_info['gocdb_name']
  $hepspec06 = $site_info['hepspec06_baseline']
  $fqdn = $facts['networking']['fqdn']

  package { [
      'htcondor-ce-apel',
      'apel-parsers',
      'apel-ssm',
      'python3-dirq',
      'python3-argo-ams-library',
      'mariadb-server',
    ]:
      ensure => installed,
  }

  # Directories used by APEL stack
  file { [
      '/var/spool/apel',
      '/var/spool/apel/outgoing',
      '/var/log/apel',
    ]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
  }

  # CE extractor timer
  service { 'condor-ce-apel.timer':
    ensure  => running,
    enable  => true,
    require => Package['htcondor-ce-apel'],
  }

  # MariaDB
  service { 'mariadb':
    ensure  => running,
    enable  => true,
    require => Package['mariadb-server'],
  }

  service { 'mariadb':
    ensure  => running,
    enable  => true,
    require => Package['mariadb-server'],
  }

  exec { 'apel-create-db-and-user':
    command => "/usr/bin/mysql -e \"CREATE DATABASE IF NOT EXISTS ${apel_db_name}; CREATE USER IF NOT EXISTS '${apel_db_user}'@'localhost' IDENTIFIED BY '${apel_db_password.unwrap}'; ALTER USER '${apel_db_user}'@'localhost' IDENTIFIED BY '${apel_db_password.unwrap}'; GRANT ALL ON ${apel_db_name}.* TO '${apel_db_user}'@'localhost'; FLUSH PRIVILEGES;\"",
    path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
    require => Service['mariadb'],
  }

  exec { 'apel-load-schema':
    command => "/usr/bin/mysql ${apel_db_name} < /usr/share/apel/client.sql",
    path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
    unless  => "/usr/bin/mysql ${apel_db_name} -e 'SHOW TABLES LIKE \"StorageRecords\";' | /bin/grep -q StorageRecords",
    require => [Package['apel-parsers'], Exec['apel-create-db-and-user']],
  }

  file { '/etc/apel/client.cfg':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/etc/apel/client.cfg.erb'),
    require => Package['apel-parsers'],
  }

  file { '/etc/apel/parser.cfg':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/etc/apel/parser.cfg.erb'),
    require => Package['apel-parsers'],
  }

  file { '/etc/apel/sender.cfg':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('profile/etc/apel/sender.cfg.erb'),
    require => Package['apel-ssm'],
  }

  # Expose vars to ERB templates
  $_apel_mysql_password = $apel_db_password.unwrap
}
