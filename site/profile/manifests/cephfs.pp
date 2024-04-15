# class for setting up Cephfs - mostly for clients and mounts
# @param cephfs_keys - the keys to use for the cephfs client
# @param install_ceph - whether to install the ceph client or not
# @param mounts - a hash of mounts to create; takes normal mount options
class profile::cephfs (
  Array[String] $keys = ['dice-reader'],
  Hash $mounts = {},
) {
  yumrepo { 'ceph-reef':
    baseurl  => 'https://download.ceph.com/rpm-reef/el9/x86_64',
    descr    => 'Ceph Reef',
    enabled  => 1,
    gpgcheck => 0,
  }
  package { 'ceph':
    ensure => latest,
  }

  # create the cephfs keys
  $keys.each |$key| {
    file { "/etc/ceph/ceph.client.${key}.keyring":
      ensure => file,
      source => "puppet:///dice_storage/cephfs/ceph.client.${key}.keyring",
      owner  => 'root',
      group  => 'root',
      mode   => '0600',
    }
  }

  file { '/etc/ceph/ceph.conf':
    ensure => file,
    source => 'puppet:///dice_storage/cephfs/ceph.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # create the mounts
  if $mounts {
    create_resources('mount', $mounts)
  }
}
