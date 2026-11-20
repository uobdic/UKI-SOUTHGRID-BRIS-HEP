# AUDITOR APEL plugin: publishes grid summaries to ARGO AMS.
#
# Install only for now: publishing stays disabled and the service stopped until
# the configuration is written and the dry run is reviewed by an operator.
#
# @param version
#   Version-release of the auditor_apel_plugin RPM (WLCG repository).
class profile::auditor::apel_publisher (
  String[1] $version = '0.11.2-1',
) {
  include profile::wlcg_repo

  package { 'auditor_apel_plugin':
    ensure  => $version,
    require => Class['profile::wlcg_repo'],
  }

  service { 'auditor_apel_plugin':
    ensure  => stopped,
    enable  => false,
    require => Package['auditor_apel_plugin'],
  }
}
