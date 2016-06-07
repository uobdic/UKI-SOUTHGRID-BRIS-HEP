class profile::mysql_server (
  $remote_hosts   = [],
  $databases      = [],
  $remote_db_user = undef,
  $remote_db_pass = undef,) {
  include profile::firewall::mysql_server

  $mysql_root_pass  = hiera('profile::mysql_server::mysql_root_pass')

  # adding perf tunings
  $override_options = {
    'mysqld' => {
      'max_connections'         => '1000',
      'query_cache_size'        => '256M',
      'query_cache_limit'       => '1MB',
      'innodb_flush_method'     => 'O_DIRECT',
      'innodb_buffer_pool_size' => '1000000000',
      'bind-address'            => $::ipaddress,
    }
  }

  class { 'mysql::server':
    service_enabled  => true,
    root_password    => $mysql_root_pass,
    override_options => $override_options,
  }

  if $remote_hosts {
    profile::mysql::grant_remove_access { $remote_hosts:
      databases => $databases,
      db_user   => $remote_db_user,
      db_pass   => $remote_db_pass,
    }
  }
}
