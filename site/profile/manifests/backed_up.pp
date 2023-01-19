# profile for backed up clients
class profile::backed_up {
  package{'veeam_restore_client':
    ensure   => 'present',
    firewall => false,
  }
}
