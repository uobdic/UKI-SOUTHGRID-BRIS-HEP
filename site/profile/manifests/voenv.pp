class profile::voenv (
) {
  $default_se      = $::site_info['storage_element']
  $vo_environments = hiera_hash('profile::voenv::vo_environments', undef)

  $defaults        = {
    'vo_default_se' => $default_se,
  }

  if $vo_environments {
    create_resources('vosupport::voenv', $vo_environments, $defaults)

    class { 'vosupport::vo_environment': voenvdefaults => $vo_environments, }
  }

  file { '/usr/etc/globus-user-env.sh': ensure => present, }

  file { 'grid-env-funcs.sh':
    path   => '/usr/libexec/grid-env-funcs.sh',
    source => 'puppet:///modules/vosupport/grid-env-funcs.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { 'clean-grid-env-funcs.sh':
    path   => '/usr/libexec/clean-grid-env-funcs.sh',
    source => 'puppet:///modules/vosupport/clean-grid-env-funcs.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
}
