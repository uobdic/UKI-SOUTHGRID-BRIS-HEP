# Class for HDFS software deployment without Cloudera Manager
class profile::hdfs_gateway(
  String $source,
  String $version,
  String $repo_file,
  String $mount_device,
  String $mount_options = 'defaults',
  String $path          = '/opt',
  Boolean $mount_hdfs   = true,
  Boolean $install_java = true,
) {
  if($install_java){
    file {'/etc/yum.repos.d/hdfs_repo.repo':
      ensure => present,
      source => $repo_file,
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
    creates => "${path}/${version}/bin/hdfs",
    path    => ['/usr/bin', '/usr/sbin', '/usr/local/bin'],
    require => File['/usr/local/bin/hdfs_setup'],
  }

  # TODO: mount still needs work, getting
  # change from 'unmounted' to 'mounted' failed: Got a nil value for should
  if($mount_hdfs){
    mount{'/hdfs':
      ensure  => 'mounted',
      device  => $mount_device,
      fstype  => 'fuse',
      options => $mount_options,
      atboot  => false,
      pass    => false,
      require => [Exec['hdfs_setup']],
      target  => '/etc/fstab',
    }
  }
}
