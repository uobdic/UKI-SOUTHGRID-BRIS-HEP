# HDFS namenode config
class role::hdfs_namenode{
class { 'linux_disable_ipv6':
  disable_ipv6 => true,
  interfaces   => ['all'],
}
}
