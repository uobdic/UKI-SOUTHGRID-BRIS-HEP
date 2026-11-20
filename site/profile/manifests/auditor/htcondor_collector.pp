# AUDITOR HTCondor collector: reads job history from the schedds into Auditor.
#
# Install only for now: the service stays stopped until the configuration is
# written and reviewed.
#
# @param version
#   Version-release of the auditor_htcondor_collector RPM (WLCG repository).
class profile::auditor::htcondor_collector (
  String[1] $version = '0.11.2-1',
) {
  include profile::wlcg_repo

  package { 'auditor_htcondor_collector':
    ensure  => $version,
    require => Class['profile::wlcg_repo'],
  }

  service { 'auditor_htcondor_collector':
    ensure  => stopped,
    enable  => false,
    require => Package['auditor_htcondor_collector'],
  }
}
