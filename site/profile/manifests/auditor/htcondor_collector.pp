# AUDITOR HTCondor collector: reads job history from the schedds into Auditor.
#
# The services stay stopped until `enable` (grid collector) and `local_enable`
# (local collector) are set: review the configuration and run the
# condor_history hand test first (see profile::auditor::htcondor_client). Both
# need the read-only token in place and the `auditor` service running.
#
# @param version
#   Version-release of the auditor_htcondor_collector RPM (WLCG repository).
# @param pool
#   HTCondor pool (central manager) passed to condor_history -pool.
# @param schedd_names
#   Schedds whose job history is collected (grid CEs, published to APEL).
# @param site_name
#   Value of the Auditor "site" meta field.
# @param record_prefix
#   Prefix of the Auditor record ids written by the grid collector.
# @param local_schedd_names
#   Local (non-grid) schedds collected by a second collector instance. Empty
#   (default): no second instance. These records are stored but not published to
#   APEL, because the APEL plugin reports only the sites in its sites_to_report.
# @param local_site_name
#   Value of the Auditor "site" meta field for the local schedds.
# @param local_record_prefix
#   Prefix of the record ids of the local instance. It must differ from
#   record_prefix: the state database and the record ids are keyed by it.
# @param state_dir
#   Directory for the collector state database.
# @param interval
#   Seconds between history queries.
# @param job_status
#   HTCondor JobStatus values to account (3 removed, 4 completed).
# @param benchmark
#   Name of the benchmark score taken from MachineAttrApelSpecs0.
# @param earliest_datetime
#   First start only: oldest job end time to collect (ISO 8601, e.g.
#   2024-01-01T00:00:00+00:00). Ignored once the state database exists.
#   Unset: start at the time of the first run.
# @param enable
#   Run the grid collector service. Keep false until the hand test works.
# @param local_enable
#   Run the local collector service (only used when local_schedd_names is set).
# @param max_overrun
#   Workaround for AUDITOR#2023 (held and then removed jobs get a runtime from
#   match to removal, so held time counts as walltime). Jobs whose recorded
#   runtime (stop time - LastMatchTime) exceeds RemoteWallClockTime by more than
#   this many seconds are not collected: their real usage is lost, but the
#   inflation is avoided. Applies to both collector instances. Unset (default):
#   no filter. Remove it once the upstream fix is released.
# @param api_addr
#   Address of the Auditor API.
# @param api_port
#   Port of the Auditor API.
class profile::auditor::htcondor_collector (
  String[1] $version = '0.11.2-1',
  String[1] $pool = 'htc01.dice.priv',
  Array[String[1], 1] $schedd_names = ['lcgce02.phy.bris.ac.uk'],
  String[1] $site_name = 'UKI-SOUTHGRID-BRIS-HEP',
  String[1] $record_prefix = 'htcondor',
  Array[String[1]] $local_schedd_names = [],
  String[1] $local_site_name = 'DICE-LOCAL',
  String[1] $local_record_prefix = 'htcondor-local',
  Stdlib::Absolutepath $state_dir = '/data/auditor/collector',
  Integer[1] $interval = 900,
  Array[Integer, 1] $job_status = [3, 4],
  String[1] $benchmark = 'HEPscore23',
  Optional[String[1]] $earliest_datetime = undef,
  Optional[Integer[0]] $max_overrun = undef,
  Boolean $enable = false,
  Boolean $local_enable = false,
  String[1] $api_addr = '127.0.0.1',
  Integer[1, 65535] $api_port = 8000,
) {
  include profile::wlcg_repo
  include profile::auditor::htcondor_client

  package { 'auditor_htcondor_collector':
    ensure  => $version,
    require => [Class['profile::wlcg_repo'], Class['profile::auditor::htcondor_client']],
  }

  file { $state_dir:
    ensure  => directory,
    owner   => 'auditor-htcondor-collector',
    group   => 'auditor',
    mode    => '0750',
    require => [Package['auditor_htcondor_collector'], File['/data/auditor']],
  }

  file { '/etc/auditor/auditor_htcondor_collector.yml':
    ensure  => file,
    owner   => 'root',
    group   => 'auditor',
    mode    => '0640',
    content => epp('profile/etc/auditor/auditor_htcondor_collector.yml.epp', {
        'api_addr'          => $api_addr,
        'api_port'          => $api_port,
        'state_db'          => "${state_dir}/htcondor_history_state.db",
        'interval'          => $interval,
        'pool'              => $pool,
        'schedd_names'      => $schedd_names,
        'job_status'        => $job_status,
        'record_prefix'     => $record_prefix,
        'site_name'         => $site_name,
        'benchmark'         => $benchmark,
        'earliest_datetime' => $earliest_datetime,
        'max_overrun'       => $max_overrun,
    }),
    require => Package['auditor_htcondor_collector'],
    notify  => Service['auditor_htcondor_collector'],
  }

  service { 'auditor_htcondor_collector':
    ensure  => $enable ? { true => running, default => stopped },
    enable  => $enable,
    require => Package['auditor_htcondor_collector'],
  }

  # Second instance for the local schedds: own config, state database, record
  # prefix and site, so APEL (which selects on site) never sees these records.
  # It stays stopped until an operator enables it, like the grid instance.
  unless empty($local_schedd_names) {
    if $local_record_prefix == $record_prefix {
      fail('profile::auditor::htcondor_collector: local_record_prefix must differ from record_prefix')
    }

    $local_config = '/etc/auditor/auditor_htcondor_collector_local.yml'

    file { $local_config:
      ensure  => file,
      owner   => 'root',
      group   => 'auditor',
      mode    => '0640',
      content => epp('profile/etc/auditor/auditor_htcondor_collector.yml.epp', {
          'api_addr'          => $api_addr,
          'api_port'          => $api_port,
          'state_db'          => "${state_dir}/htcondor_local_history_state.db",
          'interval'          => $interval,
          'pool'              => $pool,
          'schedd_names'      => $local_schedd_names,
          'job_status'        => $job_status,
          'record_prefix'     => $local_record_prefix,
          'site_name'         => $local_site_name,
          'benchmark'         => $benchmark,
          'earliest_datetime' => $earliest_datetime,
        'max_overrun'       => $max_overrun,
      }),
      require => Package['auditor_htcondor_collector'],
      notify  => Systemd::Unit_file['auditor_htcondor_collector_local.service'],
    }

    # Copy of the packaged unit with a different --config.
    systemd::unit_file { 'auditor_htcondor_collector_local.service':
      content => epp('profile/etc/systemd/auditor_htcondor_collector_local.service.epp', {
          'config' => $local_config,
      }),
      enable  => $local_enable,
      active  => $local_enable,
      require => Package['auditor_htcondor_collector'],
    }
  }
}
