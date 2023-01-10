# profile for the xrootd manager (there can be more than one - can construct a hierarchy)
class profile::xrootd::manager {
  notify { 'xrootd::manager':
    message => 'placeholder module',
  }
}
