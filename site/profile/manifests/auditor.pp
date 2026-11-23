# Auditor accounting VM: data layout, PostgreSQL on the data disk and journal cap.
#
# The data disk must be mounted at $data_dir before Puppet places any state on it;
# the catalog fails otherwise so nothing is ever written to the OS disk.
#
# @param data_dir
#   Mount point of the dedicated data disk.
# @param postgresql_version
#   PostgreSQL major version, installed from the PGDG repository.
# @param auditor_version
#   Version-release of the auditor RPM from the WLCG repository.
# @param db_password
#   Password of the auditor database role (EYAML in the private node data).
# @param api_addr
#   Address the API listens on. Keep loopback until a remote client is approved.
# @param api_port
#   API port.
# @param db_name
#   Auditor database name.
# @param db_user
#   Auditor database role.
# @param log_level
#   Auditor log level.
# @param journal_max_use
#   SystemMaxUse for journald, to keep logs from filling the OS disk.
class profile::auditor (
  Stdlib::Absolutepath $data_dir = '/data',
  String[1] $postgresql_version = '17',
  String[1] $auditor_version = '0.11.2-1',
  String[1] $db_password,
  String[1] $api_addr = '127.0.0.1',
  Stdlib::Port $api_port = 8000,
  String[1] $db_name = 'auditor',
  String[1] $db_user = 'auditor',
  String[1] $log_level = 'info',
  String[1] $journal_max_use = '500M',
) {
  unless $facts['mountpoints'] and $facts['mountpoints'][$data_dir] {
    fail("${data_dir} is not a mount point: mount the data disk before applying profile::auditor")
  }

  $pgdata = "${data_dir}/pgsql"

  # State directories. The collector's directory is managed by
  # profile::auditor::htcondor_collector (it is owned by the collector user).
  file { ["${data_dir}/auditor", "${data_dir}/auditor/apel"]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # PostgreSQL data directory: same SELinux labels as the default /var/lib/pgsql.
  if $facts['os']['selinux']['enabled'] {
    selinux::fcontext::equivalence { $pgdata:
      ensure => present,
      target => '/var/lib/pgsql',
    }
    selinux::exec_restorecon { $pgdata:
      require => Selinux::Fcontext::Equivalence[$pgdata],
      before  => Class['postgresql::server'],
    }
  }

  # PGDG packages conflict with the Rocky AppStream postgresql module stream.
  package { 'postgresql-appstream-module':
    ensure   => 'disabled',
    name     => 'postgresql',
    provider => 'dnfmodule',
    before   => Class['postgresql::server::install'],
  }

  class { 'postgresql::globals':
    datadir             => $pgdata,
    version             => $postgresql_version,
    manage_package_repo => true,
    manage_dnf_module   => false,
  }

  # Loopback only: the database is never reachable from the network.
  # The module already owns the postgresql.service drop-in, so the mount
  # dependency goes into it: PostgreSQL does not start without the data disk.
  class { 'postgresql::server':
    listen_addresses     => 'localhost',
    extra_systemd_config => "[Unit]\nRequiresMountsFor=${data_dir}\n",
    require              => Class['postgresql::globals'],
  }

  # Cap journal usage on the OS disk.
  file { '/etc/systemd/journald.conf.d':
    ensure => directory,
    mode   => '0755',
  }
  file { '/etc/systemd/journald.conf.d/50-auditor.conf':
    ensure  => file,
    mode    => '0644',
    content => "[Journal]\nSystemMaxUse=${journal_max_use}\n",
    require => File['/etc/systemd/journald.conf.d'],
    notify  => Exec['auditor-restart-journald'],
  }
  exec { 'auditor-restart-journald':
    command     => '/usr/bin/systemctl restart systemd-journald',
    refreshonly => true,
  }

  # Auditor core from the WLCG repository.
  include profile::wlcg_repo
  package { 'auditor':
    ensure  => $auditor_version,
    require => Class['profile::wlcg_repo'],
  }

  # Database and role. The password is stored hashed in PostgreSQL.
  postgresql::server::db { $db_name:
    user     => $db_user,
    password => postgresql::postgresql_password($db_user, $db_password, true),
    owner    => $db_user,
    require  => Class['postgresql::server'],
  }

  # Schema migrations shipped with the RPM, applied once each as the auditor
  # role. A marker on the data disk records each applied file, so the markers
  # and the database always come from the same disk.
  $migration_dir = "${data_dir}/auditor/migrations"
  file { $migration_dir:
    ensure  => directory,
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => File["${data_dir}/auditor"],
  }
  $migrations = [
    '20220322080444_create_accounting_table.sql',
    '20240503141800_convert_meta_component_to_jsonb.sql',
  ]
  $migrations.each |Integer $index, String $migration| {
    $marker = "${migration_dir}/${migration}.done"
    exec { "auditor-migration-${migration}":
      command  => "${postgresql::server::psql_path} -v ON_ERROR_STOP=1 --single-transaction -d ${db_name} -c 'SET ROLE ${db_user}' -f /usr/share/auditor/migrations/${migration} && touch ${marker}",
      provider => 'shell',
      user     => 'postgres',
      path     => ['/usr/bin', '/bin'],
      cwd      => '/tmp',
      creates  => $marker,
      require  => [Package['auditor'], Postgresql::Server::Db[$db_name], File[$migration_dir]],
      before   => Service['auditor'],
    }
  }

  # API configuration: the file holds the database password.
  file { '/etc/auditor/auditor.yml':
    ensure  => file,
    owner   => 'root',
    group   => 'auditor',
    mode    => '0640',
    content => Sensitive(epp('profile/etc/auditor/auditor.yml.epp', {
      addr        => $api_addr,
      port        => $api_port,
      db_name     => $db_name,
      db_user     => $db_user,
      db_password => Sensitive($db_password),
      log_level   => $log_level,
    })),
    require => Package['auditor'],
    notify  => Service['auditor'],
  }

  # Start only after PostgreSQL and with the data disk mounted.
  $pg_service = "${postgresql::server::service_name}.service"
  systemd::dropin_file { 'auditor-after-postgresql.conf':
    unit    => 'auditor.service',
    content => "[Unit]\nRequires=${pg_service}\nAfter=${pg_service}\nRequiresMountsFor=${data_dir}\n",
    require => Package['auditor'],
    notify  => Service['auditor'],
  }

  service { 'auditor':
    ensure  => running,
    enable  => true,
    require => File['/etc/auditor/auditor.yml'],
  }
}
