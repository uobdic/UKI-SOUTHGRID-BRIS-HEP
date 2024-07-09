# class to control the HTCondor systemctl service and common config
class profile::htcondor::common {
  file { '/etc/condor/config.d/00-site-common.conf':
    ensure => file,
    source => "puppet:///modules/${module_name}/etc/condor/00_site_common.conf",
  }
  service { 'condor':
    ensure => running,
    enable => true,
  }

  exec { '/usr/sbin/condor_reconfig':
    refreshonly => true,
    path        => '/usr/bin:/usr/sbin:/bin',
    unless      => 'test -f /etc/condor/config.d/19_remote_submit.config',
    require     => Service['condor'],
  }
}
