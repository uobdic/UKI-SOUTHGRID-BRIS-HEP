#
class profile::dmlite::hdfs::headnode {
  $gateways         = hiera_array('profile::dmlite::gateways')
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
  $databases        = ['dpm_db.*', 'cns_db.*']
  $disk_nodes       = join($gateways, ' ')
  $remotes          = suffix($gateways, ':2811')
  $remote_nodes     = join($remotes, ',')
  $hdfs_replication = 2

  Class['Mysql::Server'] -> Class['Lcgdm::Ns::Service']

  class { 'profile::mysql_server':
    remote_hosts   => $gateways,
    databases      => $databases,
    remote_db_user => $db_user,
    remote_db_pass => $db_pass,
  }

  include profile::firewall::dmlite_headnode
  include profile::dmlite::vo_support

  #
  # DPM and DPNS daemon configuration.
  #
  class { 'lcgdm':
    dbflavor => 'mysql',
    dbuser   => $db_user,
    dbpass   => $db_pass,
    dbhost   => $db_host,
    domain   => $localdomain,
    volist   => $supported_vos,
  }

  #
  # RFIO configuration.
  #
  class { 'lcgdm::rfio':
    dpmhost => $::fqdn,
  }

  lcgdm::shift::trust_value {
    'DPM TRUST':
      component => 'DPM',
      host      => $disk_nodes;

    'DPNS TRUST':
      component => 'DPNS',
      host      => $disk_nodes;

    'RFIO TRUST':
      component => 'RFIOD',
      host      => $disk_nodes,
      all       => true
  }

  lcgdm::shift::protocol { 'PROTOCOLS':
    component => 'DPM',
    proto     => 'rfio gsiftp http https xroot'
  }

  #
  # dmlite configuration.
  #
  class { 'dmlite::head_hdfs':
    token_password   => $token_password,
    mysql_username   => $db_user,
    mysql_password   => $db_pass,
    hdfs_namenode    => $hdfs_namenode,
    hdfs_port        => $hdfs_port,
    hdfs_user        => 'dpmmgr',
    enable_io        => true,
    hdfs_tmp_folder  => '/tmp',
    hdfs_gateway     => join($gateways, ','),
    hdfs_replication => $hdfs_replication,
  }

  #
  # Frontends based on dmlite.
  #
  class { 'dmlite::dav::install':
  }

  class { 'dmlite::dav::config':
    enable_hdfs => true
  }

  class { 'dmlite::dav::service':
  }

  class { 'dmlite::gridftp':
    dpmhost      => $::fqdn,
    remote_nodes => $remote_nodes,
    enable_hdfs  => true,
    log_level    => 'INFO',
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

  $atlas_fed = {
    name           => 'fedredir_atlas',
    fed_host       => 'atlas-xrd-uk.cern.ch',
    xrootd_port    => 1094,
    cmsd_port      => 1098,
    local_port     => 11000,
    namelib_prefix => "/dpm/${localdomain}/home/atlas",
    namelib        => "XrdOucName2NameLFC.so pssorigin=localhost sitename=UKI-SOUTHGRID-BRIS-HEP",
    paths          => ['/atlas']
  }

  $cms_fed   = {
    name           => 'fedredir_cms',
    fed_host       => 'xrootd-cms.infn.it',
    xrootd_port    => 1094,
    cmsd_port      => 1213,
    local_port     => 11001,
    namelib_prefix => "/dpm/${localdomain}/home/cms",
    namelib        => "libXrdCmsTfc.so file:/etc/xrootd/storage.xml?protocol=direct",
    paths          => ['/store']
  }

  class { 'dmlite::xrootd':
    nodetype             => ['head'],
    domain               => $localdomain,
    dpm_xrootd_debug     => $debug,
    dpm_xrootd_sharedkey => $xrootd_sharedkey,
    enable_hdfs          => true,
    xrd_report           => "xrootd.t2.ucsd.edu:9931,atl-prod05.slac.stanford.edu:9931 every 60s all sync",
    xrootd_monitor       => "all flush 30s ident 5m fstat 60 lfn ops ssq xfr 5 window 5s dest fstat info user redir CMS-AAA-EU-COLLECTOR.cern.ch:9330 dest fstat info user redir atlas-fax-eu-collector.cern.ch:9330",
    dpm_xrootd_fedredirs => { "atlas" => $atlas_fed, "cms" => $cms_fed },
  }

  # BDII
  include('bdii')

  # DPM GIP config
  class { 'lcgdm::bdii::dpm':
    sitename => 'UKI-SOUTHGRID-BRIS-HEP',
    vos      => $supported_vos,
    hdfs     => true,
  }

  Class['Lcgdm::Base::Config'] ->
  class { 'memcached':
    max_memory => 2000,
    listen_ip  => '127.0.0.1',
  } ->
  class { 'dmlite::plugins::memcache':
    expiration_limit => 600,
    posix            => 'on',
  }

  # class {'dmlite::plugins::hdfs':}

  #
  # dmlite shell configuration.
  #
  class { 'dmlite::shell':
  }

  $commands = [
    'dmlite-shell -e \'pooladd  hdfs_pool hdfs\'',
    "dmlite-shell -e 'poolmodify hdfs_pool hostname ${hdfs_namenode}'",
    "dmlite-shell -e 'poolmodify hdfs_pool port ${hdfs_port}'",
    'dmlite-shell -e \'poolmodify hdfs_pool username dpmmgr\'',
    'dmlite-shell -e \'poolmodify hdfs_pool mode rw\'']

  exec { 'configurepool':
    path        => '/bin:/sbin:/usr/bin:/usr/sbin',
    environment => ['LD_LIBRARY_PATH=/usr/lib/jvm/java/jre/lib/amd64/server/'],
    command     => join($commands, ';'),
    unless      => 'dmlite-shell -e \'poolinfo rw\'',
    require     => [Package['dmlite-shell'], Class['Dmlite::shell']],
  }

  #
  # Set inter-module dependencies
  #
  Class['Mysql::Server'] -> Class['Lcgdm::Ns::Service']
  Class['Dmlite::Plugins::Hdfs::Install'] -> Class['Dmlite::Gridftp']
  Class['Dmlite::Plugins::Hdfs::Install'] -> Class['Dmlite::Dav::Config']
  Class['Dmlite::Plugins::Hdfs::Install'] -> Class['Xrootd::Config']

  Class['Dmlite::Plugins::Mysql::Install'] -> Class['Dmlite::Gridftp']
  Class['Dmlite::Plugins::Mysql::Install'] -> Class['Dmlite::Dav::Config']
  Class['Dmlite::Plugins::Mysql::Install'] -> Class['Xrootd::Config']

  Class['Dmlite::Plugins::Hdfs::Config'] -> Class['Dmlite::Dav::Config']
  Class['Dmlite::Plugins::Hdfs::Config'] -> Class['Dmlite::Gridftp']
  Class['Dmlite::Plugins::Hdfs::Config'] -> Class['Dmlite::Xrootd']

  Class['Bdii::Install'] -> Class['Lcgdm::Bdii::Dpm']
  Class['Lcgdm::Bdii::Dpm'] -> Class['Bdii::Service']
  Class['fetchcrl::service'] -> Class['Xrootd::Config']
  Class['Lcgdm::Dpm::Service'] -> Lcgdm::Dpm::Pool <| |>
  # memcache configuration
  Class['Dmlite::Plugins::Memcache::Install'] ~> Class['Dmlite::Dav::Service']
  Class['Dmlite::Plugins::Memcache::Install'] ~> Class['Dmlite::Gridftp']
  Class['Dmlite::Plugins::Memcache::Install'] ~> Class['Xrootd::Service']
}
