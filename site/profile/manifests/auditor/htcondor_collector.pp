# AUDITOR HTCondor collector: reads job history from the schedds into Auditor.
#
# The service stays stopped until the configuration is reviewed and the
# condor_history hand test works (see profile::auditor::htcondor_client).
#
# @param version
#   Version-release of the auditor_htcondor_collector RPM (WLCG repository).
# @param pool
#   HTCondor pool (central manager) passed to condor_history -pool.
# @param schedd_names
#   Schedds whose job history is collected.
# @param site_name
#   Value of the Auditor "site" meta field.
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
# @param api_addr
#   Address of the Auditor API.
# @param api_port
#   Port of the Auditor API.
class profile::auditor::htcondor_collector (
  String[1] $version = '0.11.2-1',
  String[1] $pool = 'htc01.dice.priv',
  Array[String[1], 1] $schedd_names = ['lcgce02.phy.bris.ac.uk'],
  String[1] $site_name = 'UKI-SOUTHGRID-BRIS-HEP',
  Stdlib::Absolutepath $state_dir = '/data/auditor/collector',
  Integer[1] $interval = 900,
  Array[Integer, 1] $job_status = [3, 4],
  String[1] $benchmark = 'HEPscore23',
  Optional[String[1]] $earliest_datetime = undef,
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
        'site_name'         => $site_name,
        'benchmark'         => $benchmark,
        'earliest_datetime' => $earliest_datetime,
    }),
    require => Package['auditor_htcondor_collector'],
    notify  => Service['auditor_htcondor_collector'],
  }

  service { 'auditor_htcondor_collector':
    ensure  => stopped,
    enable  => false,
    require => Package['auditor_htcondor_collector'],
  }
}
