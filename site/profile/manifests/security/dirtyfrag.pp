# workaround for CVE-2026-43284 (EGI-SVG-2026-14)
class profile::security::dirtyfrag {
  file { '/etc/modprobe.d/mitigation-dirtyfrag.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("EOF"),
      install esp4 /bin/false
      install esp6 /bin/false
      install rxrpc /bin/false
      blacklist esp4
      blacklist esp6
      blacklist rxrpc
      | EOF
    notify  => Exec['drop_caches_after_dirtyfrag_mitigation'],
  }

  exec { 'drop_caches_after_dirtyfrag_mitigation':
    command     => '/usr/sbin/sysctl vm.drop_caches=3',
    path        => ['/usr/sbin', '/usr/bin', '/bin'],
    refreshonly => true,
  }
}
