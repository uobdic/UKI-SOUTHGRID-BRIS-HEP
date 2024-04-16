# A class for Hadoop, meant to set up clients
# @param hadoop_version The version of Hadoop to install
class profile::hdfs (
  String $hadoop_version = '3.3.6',
) {
  # install java
  package { 'java-1.8.0-openjdk-headless':
    ensure => 'installed',
  }

  # Download hadoop
  exec { "download-hadoop-${hadoop_version}":
    command => "/usr/bin/wget -O /tmp/hadoop-${hadoop_version}.tar.gz https://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz",
    creates => "/tmp/hadoop-${hadoop_version}.tar.gz",
  }
  file { "/opt/hadoop-${hadoop_version}":
    ensure => 'directory',
  }
  exec { "extract-hadoop-${hadoop_version}":
    command => "/usr/bin/tar -xzf /tmp/hadoop-${hadoop_version}.tar.gz --strip-components=1 -C /opt/hadoop-${hadoop_version}",
    creates => "/opt/hadoop-${hadoop_version}/bin/hadoop",
    require => File["/opt/hadoop-${hadoop_version}"],
  }
  # create a symlink to the hadoop version
  file { '/opt/hadoop':
    ensure => 'link',
    target => "/opt/hadoop-${hadoop_version}",
  }

  # load the config
  file { '/etc/profile.d/hadoop.sh':
    ensure => 'file',
    source => 'puppet:///modules/profile/etc/profile.d/hadoop.sh',
  }
  file { '/etc/hadoop':
    ensure => 'directory',
  } -> file { '/etc/hadoop/conf':
    ensure => 'directory',
  } -> file { '/etc/hadoop/conf/core-site.xml':
    ensure => 'file',
    source => 'puppet:///dice_store/hadoop/conf/core-site.xml',
  } -> file { '/etc/hadoop/conf/hdfs-site.xml':
    ensure => 'file',
    source => 'puppet:///dice_store/hadoop/conf/hdfs-site.xml',
  }
}
