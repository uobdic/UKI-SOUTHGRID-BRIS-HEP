# profile for the xrootd manager (there can be more than one - can construct a hierarchy)
class profile::xrootd::gateway {
  notify { 'xrootd::gateway':
    message => 'placeholder module',
  }
}
