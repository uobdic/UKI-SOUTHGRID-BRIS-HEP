class profile::firewall::mysql_server {
  firewall { '950 allow mysql':
    state  => 'NEW',
    proto  => 'tcp',
    dport  => '3306',
    action => 'accept'
  }
}
