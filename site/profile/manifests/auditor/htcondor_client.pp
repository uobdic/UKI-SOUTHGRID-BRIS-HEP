# HTCondor command-line client for the Auditor collector (it runs condor_history).
# No HTCondor daemon runs on this host; authentication is by a read-only IDTOKEN.
#
# @param version
#   condor RPM version ('present' = whatever the 24.x release repository has).
# @param token_dir
#   Directory the client reads tokens from. The token file is placed by hand.
# @param collector_host
#   HTCondor pool central manager.
class profile::auditor::htcondor_client (
  String[1] $version = 'present',
  Stdlib::Absolutepath $token_dir = '/etc/auditor/condor-token',
  String[1] $collector_host = 'htc01.dice.priv',
) {
  # Official release RPM: ships /etc/yum.repos.d/htcondor.repo and the GPG key.
  package { 'htcondor-release':
    ensure   => present,
    provider => 'rpm',
    source   => 'https://htcss-downloads.chtc.wisc.edu/repo/24.x/htcondor-release-current.el9.noarch.rpm',
  }

  package { 'condor':
    ensure  => $version,
    require => Package['htcondor-release'],
  }

  service { 'condor':
    ensure  => stopped,
    enable  => false,
    require => Package['condor'],
  }

  file { $token_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'auditor',
    mode    => '0750',
    require => Package['auditor'],
  }

  file { '/etc/condor/config.d/90-auditor-client.conf':
    ensure  => file,
    content => epp('profile/etc/condor/90-auditor-client.conf.epp', {
        'token_dir'      => $token_dir,
        'collector_host' => $collector_host,
    }),
    require => Package['condor'],
  }
}
