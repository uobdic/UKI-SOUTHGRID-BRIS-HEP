# Profile for CVMFS deployment - maps the site_info facts to cvmfs_mounts
class profile::cvmfs {
  $cvmfs_mounts     = lookup('profile::cvmfs::mounts', Hash, deep, $facts['site_info']['cvmfs_mounts'])
  $cvmfs_server_url = lookup('cvmfs::cvmfs_server_url')

  include cvmfs

  $defaults = {
    'cvmfs_server_url' => $cvmfs_server_url,
  }

  if $cvmfs_mounts {
    create_resources('cvmfs::mount', $cvmfs_mounts, $defaults)
  }

  file { '/etc/cvmfs/keys/desy.de.pub' :
    source => "puppet:///modules/${module_name}/etc/cvmfs/keys/desy.de.pub",
  }

  file { '/etc/cvmfs/keys/gridpp.ac.uk.pub' :
    source => "puppet:///modules/${module_name}/etc/cvmfs/keys/gridpp.ac.uk.pub",
  }
}
