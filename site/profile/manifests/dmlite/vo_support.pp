class profile::dmlite::vo_support {
  $supported_vos = $::site_info['supported_vos']

  # for the moment use this safe list instead of $supported_vos
  $vo_array      = ['atlas', 'cms', 'dteam', 'gridpp', 'ops', 'lhcb', 'alice', 'lsst', 'vo_southgrid_ac_uk',]
  $vos           = prefix($vo_array, 'voms::')

  class { $vos: }

  #
  # Gridmapfile configuration.
  #
  $groupmap = {
    'vomss://voms2.cern.ch:8443/voms/atlas?/atlas'      => 'atlas',
    'vomss://lcg-voms2.cern.ch:8443/voms/atlas?/atlas'  => 'atlas',
    'vomss://voms2.cern.ch:8443/voms/cms?/cms'          => 'cms',
    'vomss://lcg-voms2.cern.ch:8443/voms/cms?/cms'      => 'cms',
    'vomss://voms2.cern.ch:8443/voms/lhcb?/lhcb'        => 'lhcb',
    'vomss://lcg-voms2.cern.ch:8443/voms/lhcb?/lhcb'    => 'lhcb',
    'vomss://voms2.cern.ch:8443/voms/alice?/alice'      => 'alice',
    'vomss://lcg-voms2.cern.ch:8443/voms/alice?/alice'  => 'alice',
    'vomss://voms2.cern.ch:8443/voms/ops?/ops'          => 'ops',
    'vomss://lcg-voms2.cern.ch:8443/voms/ops?/ops'      => 'ops',
    'vomss://voms2.hellasgrid.gr:8443/voms/dteam?/dteam' => 'dteam',
    'vomss://voms.gridpp.ac.uk:8443/voms/gridpp?/gridpp' => 'gridpp',
    'vomss://voms02.gridpp.ac.uk:8443/voms/gridpp?/gridpp' => 'gridpp',
    'vomss://voms03.gridpp.ac.uk:8443/voms/gridpp?/gridpp' => 'gridpp',
    'vomss://voms.fnal.gov:8443/voms/lsst?/lsst'           => 'lsst',
    'vomss://voms1.fnal.gov:8443/voms/lsst?/lsst'          => 'lsst',
    'vomss://voms2.fnal.gov:8443/voms/lsst?/lsst'          => 'lsst',
    'vomss://voms.gridpp.ac.uk:8443/voms/vo.southgrid.ac.uk?/vo.southgrid.ac.uk'   => 'vo.southgrid.ac.uk',
    'vomss://voms02.gridpp.ac.uk:8443/voms/vo.southgrid.ac.uk?/vo.southgrid.ac.uk' => 'vo.southgrid.ac.uk',
    'vomss://voms03.gridpp.ac.uk:8443/voms/vo.southgrid.ac.uk?/vo.southgrid.ac.uk' => 'vo.southgrid.ac.uk',
  }

  lcgdm::mkgridmap::file { 'lcgdm-mkgridmap':
    configfile   => '/etc/lcgdm-mkgridmap.conf',
    mapfile      => '/etc/lcgdm-mapfile',
    localmapfile => '/etc/lcgdm-mapfile-local',
    logfile      => '/var/log/lcgdm-mkgridmap.log',
    groupmap     => $groupmap,
    localmap     => {
      'nobody'                                             => 'nogroup',
      '/C=UK/O=eScience/OU=Bristol/L=IS/CN=lukasz kreczko' => 'root'
    }
    ,
  }

  if $::node_info['role'] == 'dmlite_hdfs_headnode' {
    $cmd    = '/usr/sbin/edg-mkgridmap'
    $conf   = '/etc/lcgdm-mkgridmap.conf'
    $output = '/etc/lcgdm-mapfile'

    exec { "${cmd} --conf=${conf} --safe --output=${output}":
      require   => File['/etc/lcgdm-mkgridmap.conf'],
      subscribe => File['/etc/lcgdm-mkgridmap.conf'],
    }
  }
}
