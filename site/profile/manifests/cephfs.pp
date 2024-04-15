# class for setting up Cephfs - mostly for clients and mounts
# @param cephfs_keys - the keys to use for the cephfs client
# @param install_ceph - whether to install the ceph client or not
# @param mounts - a hash of mounts to create; takes normal mount options
class profile::cephfs (
  Array[String] $cephfs_keys = ['dice-reader'],
  Boolean $install_ceph = false,
  Hash $mounts = {},
) {
  if $install_ceph {
    yumrepo { 'ceph-reef':
      baseurl  => 'https://download.ceph.com/rpm-reef/el9/x86_64',
      descr    => 'Ceph Reef',
      enabled  => 1,
      gpgcheck => 0,
    }
    package { 'ceph':
      ensure => latest,
    }
  }

  # create the mounts
  if $mounts {
    create_resources('mount', $mounts)
  }
}
