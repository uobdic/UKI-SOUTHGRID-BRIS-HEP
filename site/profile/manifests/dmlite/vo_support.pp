#
class profile::dmlite::vo_support {
  $supported_vos = $::site_info['supported_vos']

  # for the moment use this safe list instead of $supported_vos
  $vo_array      = ['atlas', 'cms', 'dteam', 'gridpp', 'ops', 'lhcb', 'alice', 'lsst', 'lz', 'vo_southgrid_ac_uk',]
  $vos           = prefix($vo_array, 'voms::')

  class { $vos: }

  # missing voms::lz
  voms::client{'lz':
    servers => [
      {
        server => 'lzvoms.grid.hep.ph.ic.ac.uk',
        port   => '15003',
        dn     => '/C=UK/O=eScience/OU=Imperial/L=Physics/CN=lzvoms.grid.hep.ph.ic.ac.uk',
        ca_dn  => '/C=UK/O=eScienceCA/OU=Authority/CN=UK e-Science CA 2B',
      },
      {
        server => 'voms.hep.wisc.edu',
        port   => '15003',
        dn     => '/DC=org/DC=incommon/C=US/ST=WI/L=Madison/O=University of Wisconsin-Madison/OU=OCIS/CN=voms.hep.wisc.edu',
        ca_dn  => '/C=US/O=Internet2/OU=InCommon/CN=InCommon IGTF Server CA',
      }
    ]
  }
  #
  # Gridmapfile configuration.
  #
  $groupmap = {
    'vomss://voms2.cern.ch:8443/voms/atlas?/atlas'                                 => 'atlas',
    'vomss://lcg-voms2.cern.ch:8443/voms/atlas?/atlas'                             => 'atlas',
    'vomss://voms2.cern.ch:8443/voms/cms?/cms'                                     => 'cms',
    'vomss://lcg-voms2.cern.ch:8443/voms/cms?/cms'                                 => 'cms',
    'vomss://voms2.cern.ch:8443/voms/lhcb?/lhcb'                                   => 'lhcb',
    'vomss://lcg-voms2.cern.ch:8443/voms/lhcb?/lhcb'                               => 'lhcb',
    'vomss://voms2.cern.ch:8443/voms/alice?/alice'                                 => 'alice',
    'vomss://lcg-voms2.cern.ch:8443/voms/alice?/alice'                             => 'alice',
    'vomss://voms2.cern.ch:8443/voms/ops?/ops'                                     => 'ops',
    'vomss://lcg-voms2.cern.ch:8443/voms/ops?/ops'                                 => 'ops',
    'vomss://voms2.hellasgrid.gr:8443/voms/dteam?/dteam'                           => 'dteam',
    'vomss://voms.gridpp.ac.uk:8443/voms/gridpp?/gridpp'                           => 'gridpp',
    'vomss://voms02.gridpp.ac.uk:8443/voms/gridpp?/gridpp'                         => 'gridpp',
    'vomss://voms03.gridpp.ac.uk:8443/voms/gridpp?/gridpp'                         => 'gridpp',
    'vomss://voms.slac.stanford.edu:8443/voms/lsst?/lsst'                          => 'lsst',
    'vomss://lzvoms.grid.hep.ph.ic.ac.uk:8443/voms/lz?/lz'                         => 'lz',
    'vomss://voms.hep.wisc.edu:8443/voms/lz?/lz'                                   => 'lz',
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
