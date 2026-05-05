# Configure an NFS client with static mounts
#
# Automounted entries are handled separately
#
class profile::nfs::client {
  # Hiera data
  # ====================================================================

  $idmap_domain   = lookup('profile::nfs::idmap_domain', { default_value => 'nfs', value_type => String, })

  # Prepare the system
  # ====================================================================

  class { 'nfs':
    client_enabled      => true,
    server_enabled      => false,         # This is a client-only configuration
    nfs_v4_idmap_domain => $idmap_domain,
  }

  # Client mounts
  # ====================================================================

  # A separate class so it can be included by the server profile

  include profile::nfs::client::mounts
}
