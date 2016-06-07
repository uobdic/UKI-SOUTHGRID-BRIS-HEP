#
class profile::dmlite::hdfs::gateway {
  $headnode_fqdn    = hiera_array('profile::dmlite::headnode')
  $db_user          = hiera('profile::dmlite::mysql_dpm_user')
  $db_pass          = hiera('profile::dmlite::mysql_dpm_pass')
  $db_host          = hiera('profile::dmlite::db_host')
  $token_password   = hiera('profile::dmlite::token_password')
  $xrootd_sharedkey = hiera('profile::dmlite::xrootd_sharedkey')
  $debug            = hiera('profile::dmlite::debug')
  $hdfs_namenode    = hiera('profile::dmlite::hdfs_namenode')
  $hdfs_port        = hiera('profile::dmlite::hdfs_port')
  $localdomain      = hiera('profile::dmlite::localdomain')

  $supported_vos    = $::site_info['supported_vos']

  include profile::firewall::dmlite_gateway
  include profile::dmlite::vo_support

  #
  # dmlite configuration.
  #


  class { 'dmlite::disk_hdfs':
    token_password  => $token_password,
    mysql_username  => $db_user,
    mysql_password  => $db_pass,
    mysql_host      => $headnode_fqdn,
    hdfs_namenode   => $hdfs_namenode,
    hdfs_port       => $hdfs_port,
    hdfs_user       => 'dpmmgr',
    enable_io       => true,
    hdfs_tmp_folder => '/data/dpm/tmp',
  }

  #
  # Frontends based on dmlite.
  #
  class { 'dmlite::dav::install':
  }

  class { 'dmlite::dav::config':
    enable_hdfs    => true,
    dav_http_port  => 11180,
    dav_https_port => 11443,
  }

  class { 'dmlite::dav::service':
  }

  # dpmhost is not used for HDFS, but needs to be defined for the class
  # (even with bogus value)
  class { 'dmlite::gridftp':
    dpmhost     => $headnode_fqdn,
    enable_hdfs => true,
    data_node   => 1,
    log_level   => 'ERROR',
  #   log_level => 'ERROR,WARN,INFO,TRANSFER,DUMP,ALL',
  }

  # The XrootD configuration is a bit more complicated and
  # the full config (incl. federations) will be explained here:
  # https://svnweb.cern.ch/trac/lcgdm/wiki/Dpm/Xroot/PuppetSetup

  #
  # The simplest xrootd configuration.
  #
  class { 'xrootd::config':
    xrootd_user  => 'dpmmgr',
    xrootd_group => 'dpmmgr'
  }

  class { 'dmlite::xrootd':
    nodetype             => ['disk'],
    domain               => $localdomain,
    dpm_xrootd_debug     => $debug,
    dpm_xrootd_sharedkey => $xrootd_sharedkey,
    enable_hdfs          => true,
  }

  # limit conf

  $limits_config = {
    '*' => {
      nofile => {
        soft => 65000,
        hard => 65000
      }
      ,
      nproc  => {
        soft => 65000,
        hard => 65000
      }
      ,
    }
  }

  class { 'limits':
    config    => $limits_config,
    use_hiera => false
  }
  #
  # Set inter-module dependencies
  #
  Class['Dmlite::Plugins::Hdfs::Install'] -> Class['Dmlite::Gridftp']
  Class['Dmlite::Plugins::Hdfs::Install'] -> Class['Dmlite::Dav::Config']
  Class['Dmlite::Plugins::Hdfs::Install'] -> Class['Xrootd::Config']
  Class['Dmlite::Plugins::Mysql::Install'] -> Class['Dmlite::Gridftp']
  Class['Dmlite::Plugins::Mysql::Install'] -> Class['Dmlite::Dav::Config']
  Class['Dmlite::Plugins::Mysql::Install'] -> Class['Xrootd::Config']
  Class['Dmlite::Plugins::Hdfs::Config'] -> Class['Dmlite::Dav::Config']
  Class['Dmlite::Plugins::Hdfs::Config'] -> Class['Dmlite::Gridftp']
  Class['Dmlite::Plugins::Hdfs::Config'] -> Class['Dmlite::Xrootd']

  Class['fetchcrl::service'] -> Class['Xrootd::Config']
}
