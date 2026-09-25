# Thin wrapper for the xrootd redirector.
class profile::xrootd::redirector {
  class { 'profile::xrootd':
    role => 'redirector',
  }
}
