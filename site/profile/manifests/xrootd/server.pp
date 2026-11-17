# Thin wrapper for xrootd storage servers.
class profile::xrootd::server {
  class { 'profile::xrootd':
    role => 'server',
  }
}
