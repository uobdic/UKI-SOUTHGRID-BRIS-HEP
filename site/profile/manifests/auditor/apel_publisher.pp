# AUDITOR APEL plugin: publishes grid summaries to ARGO AMS.
#
# Publishing stays off until `publish_enabled` is set: the configuration is
# always written, but the service is stopped and disabled. Review a dry run by
# hand first:
#   <venv>/bin/auditor-apel-publish -c /etc/auditor/auditor_apel_plugin.yml --dry-run
#
# The AMS client certificate is the host certificate placed by profile::grid_cert
# (/etc/grid-security/hostcert.pem and hostkey.pem), shared by all plugins.
#
# @param version
#   Version-release of the auditor_apel_plugin RPM (WLCG repository).
# @param publish_enabled
#   Run the publisher service. Keep false until an operator has reviewed the dry run.
# @param sites_to_report
#   GOCDB site name => list of Auditor `site` values reported under it.
# @param benchmark_type
#   APEL benchmark type (HEPscore23, hepspec or si2k). The score of this name must
#   exist on the Auditor records (see profile::auditor::htcondor_collector).
# @param ce
#   Compute element type reported to APEL.
# @param time_json_path
#   State file of the plugin; it must be on persistent storage.
# @param report_interval
#   Seconds between reports.
# @param log_level
#   Plugin log level.
# @param log_file
#   Plugin log file.
# @param messaging_host
#   ARGO AMS host.
# @param messaging_port
#   ARGO AMS port.
# @param messaging_project
#   ARGO AMS project.
# @param messaging_topic
#   ARGO AMS topic.
# @param client_cert
#   Client certificate for AMS.
# @param client_key
#   Client key for AMS.
# @param api_addr
#   Address of the Auditor API.
# @param api_port
#   Port of the Auditor API.
class profile::auditor::apel_publisher (
  String[1] $version = '0.11.2-1',
  Boolean $publish_enabled = false,
  Hash[String[1], Array[String[1], 1]] $sites_to_report = { 'UKI-SOUTHGRID-BRIS-HEP' => ['UKI-SOUTHGRID-BRIS-HEP'] },
  String[1] $benchmark_type = 'HEPscore23',
  String[1] $ce = 'HTCondor',
  Stdlib::Absolutepath $time_json_path = '/data/auditor/apel/time.json',
  Integer[1] $report_interval = 86400,
  String[1] $log_level = 'INFO',
  Stdlib::Absolutepath $log_file = '/var/log/auditor_apel_plugin.log',
  String[1] $messaging_host = 'msg.argo.grnet.gr',
  Integer[1, 65535] $messaging_port = 8443,
  String[1] $messaging_project = 'accounting',
  String[1] $messaging_topic = 'gLite-APEL',
  Stdlib::Absolutepath $client_cert = '/etc/grid-security/hostcert.pem',
  Stdlib::Absolutepath $client_key = '/etc/grid-security/hostkey.pem',
  String[1] $api_addr = '127.0.0.1',
  Integer[1, 65535] $api_port = 8000,
) {
  include profile::wlcg_repo

  package { 'auditor_apel_plugin':
    ensure  => $version,
    require => Class['profile::wlcg_repo'],
  }

  # The file uses custom YAML tags (!Config, !MetaField, ...), so it is a template.
  file { '/etc/auditor/auditor_apel_plugin.yml':
    ensure  => file,
    owner   => 'root',
    group   => 'auditor',
    mode    => '0640',
    content => epp('profile/etc/auditor/auditor_apel_plugin.yml.epp', {
        'sites_to_report'   => $sites_to_report,
        'benchmark_type'    => $benchmark_type,
        'ce'                => $ce,
        'time_json_path'    => $time_json_path,
        'report_interval'   => $report_interval,
        'log_level'         => $log_level,
        'log_file'          => $log_file,
        'messaging_host'    => $messaging_host,
        'messaging_port'    => $messaging_port,
        'messaging_project' => $messaging_project,
        'messaging_topic'   => $messaging_topic,
        'client_cert'       => $client_cert,
        'client_key'        => $client_key,
        'api_addr'          => $api_addr,
        'api_port'          => $api_port,
    }),
    require => Package['auditor_apel_plugin'],
    notify  => Service['auditor_apel_plugin'],
  }

  service { 'auditor_apel_plugin':
    ensure  => $publish_enabled ? { true => running, default => stopped },
    enable  => $publish_enabled,
    require => Package['auditor_apel_plugin'],
  }
}
