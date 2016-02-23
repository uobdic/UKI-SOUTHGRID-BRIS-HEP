class profile::cvmfs {
  $cvmfs_mounts     = hiera_hash('site_info::cvmfs_mounts', undef)
  $cvmfs_server_url = hiera('cvmfs::cvmfs_server_url')

  include cvmfs

  $defaults = {
    'cvmfs_server_url' => $cvmfs_server_url,
  }
  create_resources('cvmfs::mount', $cvmfs_mounts)

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
}
