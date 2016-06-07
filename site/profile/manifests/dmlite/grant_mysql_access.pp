# grants access for local MySQL DBs to remote host
define profile::dmlite::grant_mysql_access (
  $remote_host = $title,
  $db_user     = undef,
  $db_pass     = undef) {
  mysql_user { "${db_user}@${remote_host}":
    ensure        => present,
    password_hash => mysql_password($db_pass),
    provider      => 'mysql',
  }

  mysql_grant { "${db_user}@${remote_host}/dpm_db.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => 'dpm_db.*',
    user       => "${db_user}@${remote_host}",
  }

  mysql_grant { "${db_user}@${remote_host}/cns_db.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => 'cns_db.*',
    user       => "${db_user}@${remote_host}",
  }
}
