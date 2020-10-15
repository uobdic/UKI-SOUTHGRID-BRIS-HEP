# Class for HDFS software deployment without Cloudera Manager
class profile::hdfs_gateway(
  String $source,
  String $version,
  String $mount_device,
  String $mount_options,
  String $path = '/opt',
  Bool $fuse_mount = true,
  Bool $install_java = true,
) {
  notify {'profile::hdfs_gateway::info':
    message => "Will install HDFS version ${version} from ${source}. Install java: ${install_java}; mount /hdfs: ${fuse_mount}"
  }

  if($install_java){
    file {'/etc/yum.repos.d/hdfs_repo.repo':
      ensure => present,
      source => 'https://stacki.dice.priv/install/carts/site-customization/files/etc/yum.repos.d/hdfs_repo.repo',
    }
    package{'oracle-j2sdk1.8.x86_64':
      ensure          => present,
      install_options => ['--enablerepo', 'hdfs_repo']
    }
  }

  file {'/usr/local/bin/hdfs_setup':
      ensure  => present,
      content => template("${module_name}/usr/local/bin/hdfs_setup.erb"),
      mode    => 'a+x',
  }

  exec {'hdfs_setup':
    creates  => "${path}/${version}/bin/hdfs",
    path     => ['/usr/bin', '/usr/sbin', '/usr/local/bin'],
    requires => File['/usr/local/bin/hdfs_setup'],
  }

  if($fuse_mount){
    mount{'/hdfs':
      ensure   => 'mounted',
      device   => $mount_device,
      fstype   => 'fuse',
      options  => $mount_options,
      atboot   => 0,
      pass     => 0,
      requires => Exec['hdfs_setup'],
    }
  }
}
