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
# @param journal_max_use
#   SystemMaxUse for journald, to keep logs from filling the OS disk.
class profile::auditor (
  Stdlib::Absolutepath $data_dir = '/data',
  String[1] $postgresql_version = '17',
  String[1] $auditor_version = '0.11.2-1',
  String[1] $journal_max_use = '500M',
) {
  unless $facts['mountpoints'] and $facts['mountpoints'][$data_dir] {
    fail("${data_dir} is not a mount point: mount the data disk before applying profile::auditor")
  }

  $pgdata = "${data_dir}/pgsql"

  # State directories for the collector and the APEL plugin (used from slice 3).
  file { ["${data_dir}/auditor", "${data_dir}/auditor/collector", "${data_dir}/auditor/apel"]:
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
}
