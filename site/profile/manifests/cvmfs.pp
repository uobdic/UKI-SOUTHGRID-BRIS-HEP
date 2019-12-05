class profile::cvmfs {
  $cvmfs_mounts     = $::site_info['cvmfs_mounts']
  $cvmfs_server_url = lookup('cvmfs::cvmfs_server_url')

  include cvmfs

  $defaults = {
    'cvmfs_server_url' => $cvmfs_server_url,
  }

  if $cvmfs_mounts {
    create_resources('cvmfs::mount', $cvmfs_mounts, $defaults)
  }

  # create folder structure for local site configuration
  file { [
    '/opt/cvmfs',
    '/opt/cvmfs/cms.cern.ch',
    '/opt/cvmfs/cms.cern.ch/SITECONF',
    '/opt/cvmfs/cms.cern.ch/SITECONF/local',
    '/opt/cvmfs/cms.cern.ch/SITECONF/local/JobConfig',
    '/opt/cvmfs/cms.cern.ch/SITECONF/local/PhEDEx',
    ]:
    ensure => directory,
  } ->
  file { '/opt/cvmfs/cms.cern.ch/SITECONF/local/JobConfig/site-local-config.xml'
  :
    ensure => present,
    source => "puppet:///modules/${module_name}/site-local-config.xml",
  } ->
  file { '/opt/cvmfs/cms.cern.ch/SITECONF/local/PhEDEx/storage.xml':
    ensure => present,
    source => "puppet:///modules/${module_name}/storage.xml",
  }

  file { '/etc/cvmfs/keys/desy.de.pub' :
    source => "puppet:///modules/${module_name}/etc/cvmfs/keys/desy.de.pub",
  }

  file { '/etc/cvmfs/keys/gridpp.ac.uk.pub' :
    source => "puppet:///modules/${module_name}/etc/cvmfs/keys/gridpp.ac.uk.pub",
  }
}
