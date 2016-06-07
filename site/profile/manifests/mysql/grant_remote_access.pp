# grants access for local MySQL DBs to remote host
define profile::dmlite::grant_mysql_access (
  $remote_host = $title,
  $databases   = [],
  $db_user     = undef,
  $db_pass     = undef) {
  # make sure we have a remote user
  mysql_user { "${db_user}@${remote_host}":
    ensure        => present,
    password_hash => mysql_password($db_pass),
    provider      => 'mysql',
  }

  $databases.each |String $database| {
    mysql_grant { "${db_user}@${remote_host}/${database}":
      ensure     => 'present',
      options    => ['GRANT'],
      privileges => ['ALL'],
      table      => $database,
      user       => "${db_user}@${remote_host}",
    }
  }
}
