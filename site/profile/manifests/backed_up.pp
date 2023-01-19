# profile for backed up clients
class profile::backed_up {
  class{'veeam_restore_client':
    ensure   => 'present',
    firewall => false,
  }
}
